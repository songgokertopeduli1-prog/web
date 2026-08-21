-- COPY SEMUA SQL INI KE SUPABASE SQL EDITOR, LALU KLIK RUN

CREATE TABLE IF NOT EXISTS public.reports (
  id text PRIMARY KEY,
  ticket text NOT NULL UNIQUE,
  waktu timestamptz NOT NULL DEFAULT now(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  nama text NOT NULL,
  kontak text NOT NULL,
  alamat text NOT NULL,
  kategori text NOT NULL,
  urgensi text NOT NULL DEFAULT 'Sedang',
  judul text NOT NULL,
  deskripsi text NOT NULL,
  foto text DEFAULT '',
  status text NOT NULL DEFAULT 'Menunggu',
  admin_decision text NOT NULL DEFAULT 'Belum ditinjau',
  catatan text DEFAULT ''
);

ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS admin_decision text NOT NULL DEFAULT 'Belum ditinjau';

ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS foto text DEFAULT '';

CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE user_id = auth.uid()
  );
$$;

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buka semua data untuk pembaca publik" ON public.reports;
DROP POLICY IF EXISTS "Warga dan admin dapat membaca laporan" ON public.reports;
DROP POLICY IF EXISTS "Warga dapat membuat laporan sendiri" ON public.reports;
DROP POLICY IF EXISTS "Admin dapat menyimpan laporan" ON public.reports;
DROP POLICY IF EXISTS "Warga dapat mengirim laporan tanpa login" ON public.reports;
DROP POLICY IF EXISTS "Hanya admin dapat mengubah laporan" ON public.reports;
DROP POLICY IF EXISTS "Hanya admin dapat menghapus laporan" ON public.reports;
DROP POLICY IF EXISTS "Admin dapat membaca keanggotaannya" ON public.admin_users;

CREATE POLICY "Warga dan admin dapat membaca laporan"
ON public.reports
FOR SELECT TO authenticated
USING (public.is_admin() OR user_id = auth.uid());

CREATE POLICY "Warga dapat mengirim laporan tanpa login"
ON public.reports
FOR INSERT TO anon, authenticated
WITH CHECK (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "Admin dapat menyimpan laporan"
ON public.reports
FOR INSERT TO authenticated
WITH CHECK (public.is_admin());

CREATE POLICY "Hanya admin dapat mengubah laporan"
ON public.reports
FOR UPDATE TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Hanya admin dapat menghapus laporan"
ON public.reports
FOR DELETE TO authenticated
USING (public.is_admin());

CREATE POLICY "Admin dapat membaca keanggotaannya"
ON public.admin_users
FOR SELECT TO authenticated
USING (user_id = auth.uid());

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT INSERT ON public.reports TO anon, authenticated;
GRANT SELECT, UPDATE ON public.reports TO authenticated;
GRANT DELETE ON public.reports TO authenticated;
GRANT SELECT ON public.admin_users TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.get_report_status(report_ticket text)
RETURNS TABLE(ticket text, status text, admin_decision text, catatan text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.ticket, r.status, r.admin_decision, r.catatan
  FROM public.reports r
  WHERE r.ticket = $1;
$$;

GRANT EXECUTE ON FUNCTION public.get_report_status(text) TO anon, authenticated;

INSERT INTO storage.buckets (id, name, public)
VALUES ('report-photos', 'report-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Warga dapat mengunggah foto laporan" ON storage.objects;
CREATE POLICY "Warga dapat mengunggah foto laporan"
ON storage.objects
FOR INSERT TO anon, authenticated
WITH CHECK (bucket_id = 'report-photos');

DROP POLICY IF EXISTS "Foto laporan dapat dilihat" ON storage.objects;
CREATE POLICY "Foto laporan dapat dilihat"
ON storage.objects
FOR SELECT TO anon, authenticated
USING (bucket_id = 'report-photos');

-- BUAT AKUN INI DULU DI AUTHENTICATION > USERS
-- Email: admin@kelurahan-sukamaju.id
-- Setelah itu jalankan SQL di bawah ini untuk menjadikannya admin.
INSERT INTO public.admin_users (user_id)
SELECT id
FROM auth.users
WHERE lower(email) = lower('admin@kelurahan-sukamaju.id')
ON CONFLICT (user_id) DO NOTHING;
