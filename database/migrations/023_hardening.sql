-- Privileged helpers trust only the JWT subject, never a caller-supplied actor.
CREATE OR REPLACE FUNCTION public.fn_is_admin(p_user uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
    IF p_user IS DISTINCT FROM auth.uid() THEN
        RETURN false;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.user_role ur
        JOIN public.role r ON r.id = ur.id_role
        WHERE ur.id_user = p_user AND r.nama = 'ADMIN'
    );
END $$;

REVOKE ALL ON FUNCTION public.fn_is_admin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_is_admin(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.fn_admin_force_add_krs(text, uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fn_admin_emergency_bypass_krs(uuid, text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fn_admin_unlock_class_grades(uuid, text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fn_admin_grant_attendance_dispensation(uuid, uuid, text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fn_admin_finalize_yudisium(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fn_admin_commit_credit_transfer(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.fn_admin_issue_academic_letter(uuid, text, uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.fn_admin_force_add_krs(text, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_admin_emergency_bypass_krs(uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_admin_unlock_class_grades(uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_admin_grant_attendance_dispensation(uuid, uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_admin_finalize_yudisium(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_admin_commit_credit_transfer(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_admin_issue_academic_letter(uuid, text, uuid) TO authenticated;
