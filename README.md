# PrintBridge — GitHub Pages + Supabase

A responsive printer driver/BarTender resource portal with a Supabase-backed administrator dashboard, MEGA download links, printer model search, operating-system filters and a customer remote-support form.

## Deployment

1. Create a **Supabase project** and open **SQL Editor**. Run **`supabase.sql`** as a whole script in a new project.
2. In Supabase **Authentication → Users**, create an admin account (email + strong password). **Disable open sign-ups** if admin accounts are created manually. Copy its **User UID**.
3. In SQL Editor run (replace UUID):
   ```sql
   insert into public.printbridge_admins(user_id)
   values ('YOUR-AUTH-USER-UUID');
   ```
4. In Supabase **Project Settings → API** copy **Project URL** and **publishable/anon key** into `config.js`. **Never put the service_role or secret key here.**
5. Upload the whole `printbridge` folder contents into a GitHub repository, e.g. `yourname/printbridge`. Commit the files.
6. In GitHub **Settings → Pages**, choose **Deploy from a branch**, `main`, `/ (root)`, and save. Your site becomes `https://yourname.github.io/printbridge/` (allow deployment time).
7. Open your site, click **Partner Admin**, sign in. Create **Downloads**, add MEGA HTTPS URLs for each printer driver, utility, setup guide, and BarTender installer. You can edit/delete resources, brands, dealers and devices, and review support requests.

## Tables (all names begin `printbridge_`)

| Table | Purpose |
|---|---|
| `printbridge_admins` | Approved admin accounts, references Supabase Auth user IDs |
| `printbridge_brands` | Device brands |
| `printbridge_devices` | Models, device types, images and visibility |
| `printbridge_resources` | MEGA software/driver/manual URLs, OS and version |
| `printbridge_dealers` | Dealers listed in the remote support form |
| `printbridge_support_requests` | Customer support inquiries and statuses |

`printbridge_is_admin()` is a database helper function to enforce all edit privileges through **Row Level Security**. Normal visitors can browse active catalogue records and submit requests, but **cannot read other customers' support requests or modify catalogue records**.

## Files

- `index.html` — site layout
- `styles.css` — styling and responsive design
- `app.js` — dynamic catalogue, search, downloads, forms and admin operations
- `config.js` — public Supabase project URL + publishable key only
- `supabase.sql` — database schema, RLS policies and 3 example device records
- `assets/` — illustrations cropped from supplied concept plus placeholder

## Important operational notes

- This is a **static site**: GitHub Pages serves HTML/CSS/JS, Supabase provides authentication/database. No GitHub Actions server is needed.
- Drivers and BarTender installers **are not stored in Supabase**. Admins paste their verified HTTPS MEGA links. External files can be moved or removed, so check them regularly.
- Only distribute BarTender software with appropriate **licensing/redistribution permission**. Do not supply license keys or unauthorized installers.
- Device images support a URL (for example a public image hosted on your domain or a Supabase Storage public URL), or project-relative path. For a custom local image, commit it inside `assets/`.
- Before accepting high-volume public requests, protect `printbridge_support_requests` with **Turnstile/CAPTCHA and server-side rate limiting via a Supabase Edge Function**. The included form has a basic spam honeypot, which is *not* sufficient against automated abuse.
- Host over HTTPS (GitHub Pages does that). Restrict admin account creation, enable MFA for admins when available, and rotate compromised credentials.
- The language toggle translates the key page headings, not every form label; add translations to `app.js` if full bilingual support is desired.
- Guide/driver OS filters only show a device when a matching linked resource exists. To show all devices again, set OS to **All operating systems**.
- For bulk records, use Supabase Table Editor or CSV import; the web admin supports single-record CRUD.
