// --- เพิ่มบรรทัดนี้ไว้บนสุดของไฟล์ ---
/// <reference types="firebase-admin/firestore" />

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import {
  getFirestore,
  Timestamp,
  FieldValue,
} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();
const REGION = "asia-southeast1";

const snapWithId = <T extends Record<string, any>>(
  s: FirebaseFirestore.DocumentSnapshot
): T & { id: string } => ({ id: s.id, ...(s.data() as any) });

// =================================================================
// ============== ฟังก์ชัน `createPackageWithDetails` (แก้ไขใหม่) ======
// =================================================================
export const createPackageWithDetails = onCall(
  { region: REGION },
  async (req) => {
    // 1. ตรวจสอบการยืนยันตัวตน
    if (!req.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Login required to create a package."
      );
    }

    // 2. ดึงข้อมูลจาก client
    const {
      receiverId,
      packageDescription,
      itemImageUrl,
      senderInfo,
      receiverInfo,
    } = req.data || {};

    const senderId = req.auth.uid;

    // 3. ตรวจสอบข้อมูลว่าครบถ้วนหรือไม่
    if (
      !receiverId ||
      !packageDescription ||
      !itemImageUrl ||
      !senderInfo ||
      !receiverInfo
    ) {
      throw new HttpsError("invalid-argument", "Required data is missing.");
    }

    try {
      // 4. เตรียมข้อมูลสำหรับบันทึกลง Firestore
      const packageData = {
        // --- ข้อมูลหลัก ---
        sender_user_id: senderId,
        receiver_user_id: receiverId,
        package_description: packageDescription,
        proof_image_url: itemImageUrl,
        created_at: Timestamp.now(),
        status: "pending", // สถานะเริ่มต้นสำหรับ Rider
        rider_id: null,

        // --- ข้อมูล Snapshot ของผู้ส่งและผู้รับ ---
        sender_info: {
          name: senderInfo.name || "ไม่ระบุ",
          phone: senderInfo.phone || "ไม่ระบุ",
          address: senderInfo.address || "ไม่ระบุ",
        },
        receiver_info: {
          name: receiverInfo.name || "ไม่ระบุ",
          phone: receiverInfo.phone || "ไม่ระบุ",
          address: receiverInfo.address || "ไม่ระบุ",
        },
      };

      // 5. สร้างเอกสารใหม่ใน collection 'packages'
      const packageRef = await db.collection("packages").add(packageData);

      // 6. ส่งผลลัพธ์กลับไปยัง Client
      return {
        success: true,
        packageId: packageRef.id,
        message: "Package created successfully!",
      };
    } catch (error) {
      console.error("Error creating package with details:", error);
      throw new HttpsError(
        "internal",
        "An unexpected error occurred while creating the package."
      );
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

  let sender, receiver;
  if (pkg.sender_user_id) {
    const s = await db.collection("users").doc(pkg.sender_user_id).get().catch(() => null);
    if (s?.exists) sender = snapWithId(s);
  }
  if (pkg.receiver_user_id) {
    const r = await db.collection("users").doc(pkg.receiver_user_id).get().catch(() => null);
    if (r?.exists) receiver = snapWithId(r);
  }
  
  const addressFrom = pkg.sender_info?.address;
  const addressTo = pkg.receiver_info?.address;
  const itemDetails = { image_url: pkg.proof_image_url, description: pkg.package_description };
  
  let rider;
  if (pkg.rider_id) {
    const r = await db.collection("riders").doc(pkg.rider_id).get().catch(() => null);
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
  let q: FirebaseFirestore.Query = db.collection("packages");
  if (status) q = q.where("status", "==", status);
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