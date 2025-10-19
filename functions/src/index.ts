// --- เพิ่มบรรทัดนี้ไว้บนสุดของไฟล์ ---
/// <reference types="firebase-admin/firestore" />

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import {
  getFirestore,
  Timestamp,
  FieldValue,
  DocumentReference,
} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();
const REGION = "asia-southeast1";

const snapWithId = <T extends Record<string, any>>(
  s: FirebaseFirestore.DocumentSnapshot
): T & { id: string } => ({ id: s.id, ...(s.data() as any) });

// =================================================================
// ============== ฟังก์ชัน `createPackageWithDetails` (ตัวใหม่) ======
// =================================================================

interface ItemData {
  description: string;
  proof_image_url: string;
}

export const createPackageWithDetails = onCall(
  { region: REGION },
  async (req) => {
    // 1. ตรวจสอบว่าผู้ใช้ล็อกอินหรือยัง
    if (!req.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Login required to create a package."
      );
    }

    // 2. ดึงข้อมูลจาก payload ที่ส่งมาจากแอป
    const { receiverId, pkgDescription, item, receiverInfo } = req.data || {};

    const senderId = req.auth.uid; // ID ผู้สร้างคือผู้ที่ล็อกอินอยู่

    // 3. ตรวจสอบข้อมูลว่าครบถ้วนหรือไม่
    if (!receiverId || !pkgDescription || !item || !receiverInfo) {
      throw new HttpsError(
        "invalid-argument",
        "Required data is missing (receiverId, pkgDescription, item, receiverInfo)."
      );
    }

    try {
      // 4. สร้างเอกสารใหม่ใน collection 'packages'
      const packageRef = db.collection("packages").doc();

      await packageRef.set({
        sender_id: senderId, // ID ผู้สร้าง (ผู้ส่ง)
        receiver_id: receiverId, // ID ผู้รับ
        description: pkgDescription, // ข้อความที่ส่งถึง

        // ข้อมูลผู้รับ (snapshot ณ เวลาที่สร้าง)
        receiver_snapshot: {
          name: receiverInfo.name,
          phone_number: receiverInfo.phone_number,
          address: receiverInfo.address,
        },

        // ข้อมูลสินค้า
        item_details: {
          description: item.description,
          image_url: item.proof_image_url, // URL รูปสินค้า
        },

        current_status: "created", // สถานะเริ่มต้น
        created_at: Timestamp.now(), // วันที่และเวลาที่สร้าง
        rider_id: null,
      });

      // 5. ส่งข้อมูล ID ของ package ที่สร้างเสร็จกลับไป
      return {
        packageId: packageRef.id,
        message: "Package created successfully!",
      };
    } catch (error) {
      console.error("Error creating package with details:", error);
      throw new HttpsError("internal", "An unexpected error occurred.");
    }
  }
);

// =================================================================
// =========== ฟังก์ชันอื่นๆ (เหมือนเดิม ไม่ต้องแก้ไข) =============
// =================================================================

export const getPackageById = onCall({ region: REGION }, async (req) => {
  const { packageId } = req.data || {};
  if (!packageId)
    throw new HttpsError("invalid-argument", "packageId is required");

  const pkgDoc = await db.collection("packages").doc(packageId).get();
  if (!pkgDoc.exists) throw new HttpsError("not-found", "package not found");
  const pkg = snapWithId(pkgDoc);

  let sender: any = null,
    receiver: any = null;
  if (pkg.sender_id) {
    const s = await db
      .collection("users")
      .doc(pkg.sender_id)
      .get()
      .catch(() => null);
    if (s?.exists) sender = snapWithId(s);
  }
  if (pkg.receiver_id) {
    const r = await db
      .collection("users")
      .doc(pkg.receiver_id)
      .get()
      .catch(() => null);
    if (r?.exists) receiver = snapWithId(r);
  }

  // ข้อมูล address และ item อยู่ใน pkg แล้ว
  const addressFrom =
    pkg.addsender || (pkg.sender_snapshot ? pkg.sender_snapshot.address : null);
  const addressTo =
    pkg.addreceiver ||
    (pkg.receiver_snapshot ? pkg.receiver_snapshot.address : null);
  const itemDetails = pkg.item_details || null;

  let rider: any = null;
  if (pkg.rider_id) {
    const r = await db
      .collection("riders")
      .doc(pkg.rider_id)
      .get()
      .catch(() => null);
    if (r?.exists) rider = snapWithId(r);
  }

  return {
    package: pkg,
    sender,
    receiver,
    address_from: addressFrom,
    address_to: addressTo,
    rider,
    item: itemDetails,
  };
});

export const listPackages = onCall({ region: REGION }, async (req) => {
  const { status, limit = 50 } = req.data || {};
  let q = db.collection("packages") as FirebaseFirestore.Query;
  if (status) q = q.where("current_status", "==", status);
  q = q.orderBy("created_at", "desc").limit(Math.min(Number(limit) || 50, 100));
  const snap = await q.get();
  return snap.docs.map((d) => snapWithId(d));
});

export const listAssignedPackages = onCall({ region: REGION }, async (req) => {
  const { riderId, limit = 50 } = req.data || {};
  if (!riderId) throw new HttpsError("invalid-argument", "riderId is required");
  const q = db
    .collection("packages")
    .where("rider_id", "==", riderId)
    .orderBy("created_at", "desc")
    .limit(Math.min(Number(limit) || 50, 100));
  const snap = await q.get();
  return snap.docs.map((d) => snapWithId(d));
});

export const setRiderAvailability = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const { available } = req.data || {};
  if (typeof available !== "boolean")
    throw new HttpsError("invalid-argument", "available:boolean required");
  await db
    .collection("riders")
    .doc(req.auth.uid)
    .set({ is_available: available }, { merge: true });
  return { ok: true };
});

export const updateRiderLocation = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const { lat, lng } = req.data || {};
  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new HttpsError("invalid-argument", "lat/lng:number required");
  }
  await db.collection("riders").doc(req.auth.uid).set(
    {
      current_latitude: lat,
      current_longitude: lng,
      location_updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { ok: true };
});

export const registerRider = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const { name, licensePlate } = req.data || {};
  if (!name || !licensePlate)
    throw new HttpsError("invalid-argument", "name, licensePlate required");

  const uid = req.auth.uid;
  await db.collection("riders").doc(uid).set(
    {
      user_id: uid,
      name,
      license_plate: licensePlate,
      is_available: false,
      current_latitude: null,
      current_longitude: null,
      created_at: Timestamp.now(),
    },
    { merge: true }
  );

  const snap = await db.collection("riders").doc(uid).get();
  return snapWithId(snap);
});
