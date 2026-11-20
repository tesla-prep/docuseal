## CIRQLE fork

CIRQLE's DocuSeal at https://sign.cirqlecirqle.com. The `cirqle` branch is the latest upstream release plus the changes below, kept small so each release merges cleanly. Modified by CIRQLE since 2026-11-20 (AGPL-3.0 §5(a)); everything else is upstream DocuSeal.

- **Sign-in through Keycloak (OpenID Connect).** `config/initializers/devise_cirqle_oidc.rb`, `app/controllers/users/omniauth_callbacks_controller.rb`, `app/views/devise/sessions/_omniauthable.html.erb` and `new.html.erb`, `app/controllers/sessions_controller.rb`, `app/models/user.rb`, `config/routes.rb`, `Gemfile`. With `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` and `HOST` set, the sign-in page shows only "Continue with CIRQLE SSO", password sign-in is refused, and the first SSO sign-in creates the user by email.
- **No Pro upsell.** Emptied placeholders: `templates_code_modal/_placeholder`, `notifications_settings/_reminder_placeholder`, `sso_settings/_placeholder`, `sms_settings/_placeholder`, `personalization_settings/_logo_placeholder`, `submissions/_send_sms_button`, `esign_settings/_default_signature_row`, `users/_role_select`. Removed links: Upgrade (`shared/_navbar_buttons`), Console (`shared/_navbar`), Plans, Console, SMS and SSO (`shared/_settings_nav`), console "Learn more" (`templates/_embedding`), the bulk-send tab (`submissions/new`), locked phone and QES fields (`template_builder/fields.vue`), condition and formula menu items (`template_builder/field_settings.vue`, `field_context_menu.vue`).
- **Source link** next to "Powered by DocuSeal" (AGPL-3.0 §13; the attribution stays per §7(b)): `shared/_cirqle_source_link.html.erb`, `shared/_powered_by.html.erb`.
- **Image.** `.github/workflows/cirqle-image.yml` pushes `ghcr.io/tesla-prep/docuseal:cirqle-<sha>` for every push to `cirqle` and `capy/**`, plus `:cirqle` for the branch head.

### Taking a new upstream release

```sh
git remote add upstream https://github.com/docusealco/docuseal.git   # once
git fetch upstream --tags
git switch -c capy/upstream-3.3.9 origin/cirqle                       # 3.3.9 = the new release tag
git merge 3.3.9
# Conflicts can only be in the files above: keep upstream's change and re-apply ours.
# Emptied placeholders stay empty; delete any new "Unlock with DocuSeal Pro" placeholder the same way:
grep -rn "unlock_with_docuseal_pro\|console_redirect_index_path\|docuseal.com/pricing" app/views app/javascript
git push origin capy/upstream-3.3.9                                   # never push upstream tags: upstream docker.yml runs on them
```

Open a pull request into `cirqle`. CI (upstream `ci.yml`) and the image build run on the push; deploy the `cirqle-<sha>` image as described in tesla-prep/cirqle-sso `docs/16_DOCUSEAL.md`.

<h1 align="center" style="border-bottom: none">
  <div>
    <a href="https://www.docuseal.com">
      <img  alt="DocuSeal" src="https://github.com/user-attachments/assets/38b45682-ffa4-4919-abde-d2d422325c44" width="80" />
      <br>
    </a>
    DocuSeal
  </div>
</h1>
<h3 align="center">
  Open source document filling and signing
</h3>
<p align="center">
  <a href="https://hub.docker.com/r/docuseal/docuseal">
    <img alt="Docker releases" src="https://img.shields.io/docker/v/docuseal/docuseal">
  </a>
  <a href="https://discord.gg/qygYCDGck9">
    <img src="https://img.shields.io/discord/1125112641170448454?logo=discord"/>
  </a>
  <a href="https://twitter.com/intent/follow?screen_name=docusealco">
    <img src="https://img.shields.io/twitter/follow/docusealco?style=social" alt="Follow @docusealco" />
  </a>
</p>
<p>
DocuSeal is an open source platform that provides secure and efficient digital document signing and processing. Create PDF forms to have them filled and signed online on any device with an easy-to-use, mobile-optimized web tool.
</p>
<h2 align="center">
  <a href="https://demo.docuseal.tech">✨ Live Demo</a>
  <span>|</span>
  <a href="https://docuseal.com/sign_up">☁️ Try in Cloud</a>
</h2>

[![Demo](https://github.com/user-attachments/assets/8344a341-96cf-4df3-aaae-5458a21a65b3)](https://demo.docuseal.tech)

## Features
- PDF form fields builder (WYSIWYG)
- 12 field types available (Signature, Date, File, Checkbox etc.)
- Multiple submitters per document
- Automated emails via SMTP
- Files storage on disk or AWS S3, Google Storage, Azure Cloud
- Automatic PDF eSignature
- PDF signature verification
- User management
- Mobile-optimized signing
- 7 UI languages with signing available in 14 languages
- API and Webhooks for integrations
- Easy to deploy in minutes
- Mobile apps for [iOS](https://apps.apple.com/us/app/docuseal-e-signature/id6823564236) and [Android](https://play.google.com/store/apps/details?id=com.docuseal.app)

## Pro Features
- Company logo and white-label
- User roles
- Automated reminders
- Invitation and identity verification via SMS
- Conditional fields and formulas
- Bulk send with CSV, XLSX spreadsheet import
- SSO / SAML
- Template creation with HTML API ([Guide](https://www.docuseal.com/guides/create-pdf-document-fillable-form-with-html-api))
- Template creation with PDF or DOCX and field tags API ([Guide](https://www.docuseal.com/guides/use-embedded-text-field-tags-in-the-pdf-to-create-a-fillable-form))
- Embedded signing form ([React](https://github.com/docusealco/docuseal-react), [Vue](https://github.com/docusealco/docuseal-vue), [Angular](https://github.com/docusealco/docuseal-angular) or [JavaScript](https://www.docuseal.com/docs/embedded))
- Embedded document form builder ([React](https://github.com/docusealco/docuseal-react), [Vue](https://github.com/docusealco/docuseal-vue), [Angular](https://github.com/docusealco/docuseal-angular) or [JavaScript](https://www.docuseal.com/docs/embedded))
- [Learn more](https://www.docuseal.com/pricing)

## Deploy

|Heroku|Railway|
|:--:|:---:|
| [<img alt="Deploy on Heroku" src="https://www.herokucdn.com/deploy/button.svg" height="40">](https://heroku.com/deploy?template=https://github.com/docusealco/docuseal-heroku) | [<img alt="Deploy on Railway" src="https://railway.app/button.svg" height="40">](https://railway.com/deploy/IGoDnc?referralCode=ruU7JR)|
|**DigitalOcean**|**Render**|
| [<img alt="Deploy on DigitalOcean" src="https://www.deploytodo.com/do-btn-blue.svg" height="40">](https://cloud.digitalocean.com/apps/new?repo=https://github.com/docusealco/docuseal-digitalocean/tree/master&refcode=421d50f53990) | [<img alt="Deploy to Render" src="https://render.com/images/deploy-to-render-button.svg" height="40">](https://render.com/deploy?repo=https://github.com/docusealco/docuseal-render)

#### Docker

```sh
docker run --name docuseal -p 3000:3000 -v.:/data docuseal/docuseal
```

By default DocuSeal docker container uses an SQLite database to store data and configurations. Alternatively, it is possible to use PostgreSQL or MySQL databases by specifying the `DATABASE_URL` env variable.

#### Docker Compose

Download docker-compose.yml into your private server:
```sh
curl https://raw.githubusercontent.com/docusealco/docuseal/master/docker-compose.yml > docker-compose.yml
```

Run the app under a custom domain over https using docker compose (make sure your DNS points to the server to automatically issue ssl certs with Caddy):
```sh
sudo HOST=your-domain-name.com docker compose up
```

## For Businesses
### Integrate seamless document signing into your web or mobile apps with DocuSeal

At DocuSeal we have expertise and technologies to make documents creation, filling, signing and processing seamlessly integrated with your product. We specialize in working with various industries, including **Banking, Healthcare, Transport, Real Estate, eCommerce, KYC, CRM, and other software products** that require bulk document signing. By leveraging DocuSeal, we can assist in reducing the overall cost of developing and processing electronic documents while ensuring security and compliance with local electronic document laws.

[Book a Meeting](https://www.docuseal.com/contact)

## License

Distributed under the AGPLv3 License with Section 7(b) Additional Terms. See [LICENSE](https://github.com/docusealco/docuseal/blob/master/LICENSE) and [LICENSE_ADDITIONAL_TERMS](https://github.com/docusealco/docuseal/blob/master/LICENSE_ADDITIONAL_TERMS) for more information.
Unless otherwise noted, all files © 2023-2026 DocuSeal LLC.

## Tools

- [Signature Maker](https://www.docuseal.com/online-signature)
- [Sign Document Online](https://www.docuseal.com/sign-documents-online)
- [Fill PDF Online](https://www.docuseal.com/fill-pdf)
