import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  PutBucketCorsCommand
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { createRemoteJWKSet, jwtVerify } from "jose";

const APP_ORIGIN = "https://cloud.ethandigitalacademy.org";
const BUCKET = process.env.NEON_STORAGE_BUCKET || "ethan-cloud-files";
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const required = [
  "NEON_AUTH_JWKS_URL",
  "AWS_ENDPOINT_URL_S3",
  "AWS_REGION",
  "AWS_ACCESS_KEY_ID",
  "AWS_SECRET_ACCESS_KEY"
];
const missing = required.filter((key) => !process.env[key]);
if (missing.length) {
  console.error("[Ethan Cloud storage] Missing server environment values:", missing.join(", "));
}

const s3 = new S3Client({
  region: process.env.AWS_REGION,
  endpoint: process.env.AWS_ENDPOINT_URL_S3,
  forcePathStyle: true,
  requestChecksumCalculation: "WHEN_REQUIRED",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || ""
  }
});

const jwks = process.env.NEON_AUTH_JWKS_URL
  ? createRemoteJWKSet(new URL(process.env.NEON_AUTH_JWKS_URL))
  : null;

let corsSetup;
async function ensureBucketCors() {
  if (!corsSetup) {
    corsSetup = s3.send(new PutBucketCorsCommand({
      Bucket: BUCKET,
      CORSConfiguration: {
        CORSRules: [{
          AllowedOrigins: [APP_ORIGIN],
          AllowedMethods: ["GET", "HEAD", "PUT"],
          AllowedHeaders: ["*"],
          ExposeHeaders: ["ETag"],
          MaxAgeSeconds: 3600
        }]
      }
    })).catch((error) => {
      corsSetup = null;
      throw error;
    });
  }
  return corsSetup;
}

function send(res, status, body) {
  res.setHeader("Cache-Control", "no-store, max-age=0");
  return res.status(status).json(body);
}

async function readBody(req) {
  if (req.body && typeof req.body === "object" && !Buffer.isBuffer(req.body)) return req.body;
  if (Buffer.isBuffer(req.body)) return JSON.parse(req.body.toString("utf8"));
  if (typeof req.body === "string" && req.body) return JSON.parse(req.body);
  return {};
}

async function getUserId(req) {
  if (!jwks) throw new Error("Neon token verification is not configured.");
  const header = req.headers.authorization || req.headers.Authorization || "";
  const match = /^Bearer\s+(.+)$/i.exec(String(header));
  if (!match) {
    const error = new Error("Sign in to Ethan Cloud before accessing files.");
    error.statusCode = 401;
    throw error;
  }

  const { payload } = await jwtVerify(match[1], jwks);
  const userId = String(payload.sub || "");
  if (!UUID_RE.test(userId) || payload.role !== "authenticated") {
    const error = new Error("Your Ethan Cloud session is not valid. Sign in again.");
    error.statusCode = 401;
    throw error;
  }
  return userId;
}

function userObjectKey(userId, key) {
  if (typeof key !== "string" || key.length > 1024 || !key.startsWith(userId + "/")) {
    const error = new Error("You can only access files in your own Ethan Cloud folder.");
    error.statusCode = 403;
    throw error;
  }
  const segments = key.split("/");
  if (segments.some((part) => !part || part === "." || part === "..") || key.includes("\\")) {
    const error = new Error("The requested storage path is not valid.");
    error.statusCode = 400;
    throw error;
  }
  return key;
}

export default async function handler(req, res) {
  const origin = req.headers.origin || "";
  if (origin && origin !== APP_ORIGIN) return send(res, 403, { error: "Origin not allowed." });
  res.setHeader("Vary", "Origin");
  res.setHeader("Access-Control-Allow-Origin", APP_ORIGIN);
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST") return send(res, 405, { error: "Method not allowed." });
  if (missing.length) return send(res, 503, { error: "Ethan Cloud storage is not fully configured yet." });

  try {
    const userId = await getUserId(req);
    const body = await readBody(req);
    const action = String(body.action || "");
    const key = userObjectKey(userId, body.key);

    if (action === "upload") {
      const contentType = String(body.contentType || "application/octet-stream").slice(0, 180);
      if (!/^[A-Za-z0-9!#$&^_.+-]+\/[A-Za-z0-9!#$&^_.+-]+$/.test(contentType)) {
        return send(res, 400, { error: "The file content type is not valid." });
      }
      await ensureBucketCors();
      const url = await getSignedUrl(
        s3,
        new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType }),
        { expiresIn: 300 }
      );
      return send(res, 200, {
        url,
        method: "PUT",
        headers: { "Content-Type": contentType },
        expiresIn: 300
      });
    }

    if (action === "download") {
      await ensureBucketCors();
      const requested = Number(body.expiresIn) || 600;
      const expiresIn = Math.min(604800, Math.max(60, Math.floor(requested)));
      const downloadName = String(body.downloadName || "").replace(/[\r\n"\\]/g, "_").slice(0, 180);
      const command = new GetObjectCommand({
        Bucket: BUCKET,
        Key: key,
        ...(downloadName ? { ResponseContentDisposition: 'attachment; filename="' + downloadName + '"' } : {})
      });
      const url = await getSignedUrl(s3, command, { expiresIn });
      return send(res, 200, { url, expiresIn });
    }

    if (action === "delete") {
      await s3.send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }));
      return send(res, 200, { ok: true });
    }

    return send(res, 400, { error: "Unknown storage action." });
  } catch (error) {
    const status = Number(error.statusCode) || (error.code === "ERR_JWT_EXPIRED" ? 401 : 500);
    console.error("[Ethan Cloud storage]", error.code || error.name || "Error", error.message || "");
    return send(res, status, {
      error: status >= 500
        ? "The Neon file service could not complete this request. Please retry."
        : error.message || "The storage request was not authorised."
    });
  }
}
