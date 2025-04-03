/* eslint-disable */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";


admin.initializeApp();

interface CreateAdminData {
    email: string;
    password: string;
    displayName: string;
    role: string;
    permissions: string[];
}

export const createAdmin = functions.https.onCall(
    async (
        request: functions.https.CallableRequest<CreateAdminData>
    ) => {
        const data = request.data;
        const context = request.auth;

        // 첫 관리자 계정 생성 여부 확인
        const adminsSnapshot = await admin
            .firestore()
            .collection("admins")
            .get();
        const isFirstAdmin = adminsSnapshot.empty;

        // 첫 관리자가 아니라면 호출한 사용자가 admin 커스텀 클레임을
        // 가지고 있어야 관리자 계정을 생성할 수 있음
        if (!isFirstAdmin && (!context || !context.token.admin)) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "관리자 권한이 필요합니다."
            );
        }

        const { email, password, displayName, role, permissions } = data;

        try {
            // Firebase Auth에 새 사용자 생성
            const userRecord = await admin.auth().createUser({
                email: email,
                password: password,
                displayName: displayName,
            });
            // 새 사용자에게 관리자 권한 부여
            await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
            // Firestore admins 컬렉션에 관리자 정보 저장
            await admin
                .firestore()
                .collection("admins")
                .doc(userRecord.uid)
                .set({
                    email: email,
                    name: displayName,
                    role: isFirstAdmin ? "superAdmin" : role,
                    permissions: isFirstAdmin ? getAllPermissions() : permissions,
                    isActive: true,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
                    createdBy: isFirstAdmin
                        ? "System"
                        : (context?.token.name || "Unknown"),
                });
            return { success: true, uid: userRecord.uid };
        } catch (error) {
            console.error("Error creating admin:", error);
            throw new functions.https.HttpsError(
                "internal",
                (error as Error).message
            );
        }
    }
);

/**
 * 모든 관리자 권한 목록을 반환합니다.
 * @return {string[]} 권한 목록
 */
function getAllPermissions(): string[] {
    return [
        "view_admins",
        "create_admin",
        "edit_admin",
        "edit_admin_role",
        "edit_admin_permissions",
        "toggle_admin_status",
        "reset_admin_password",
    ];
}
