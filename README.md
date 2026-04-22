<div dir="rtl" align="right">

# GDFP

ساخته شده توسط **Dnt3e** &nbsp;|&nbsp; پروژه‌ی اصلی: [masterking32/MasterHttpRelayVPN](https://github.com/masterking32/MasterHttpRelayVPN/tree/python_testing)

---

## GDFP چیه؟
<div dir="rtl" align="center">

![Banner](https://raw.githubusercontent.com/Dnt3e/GDFP/refs/heads/main/gpdf.png)
<div dir="rtl" align="right">

 یه اسکریپت نصب‌کننده MasterHttpRelayVPN بر روی سرور برای لینوکس اوبونتو هست که کار نصب، تنظیم و مدیریت پروکسی [MasterHttpRelayVPN](https://github.com/masterking32/MasterHttpRelayVPN/tree/python_testing) رو برات خودکار می‌کنه.

پروکسی اصلی یه ابزار فیلترشکن رایگانه که ترافیک اینترنتت رو پشت دامنه‌های معتبر مثل Google قایم می‌کنه. فیلترینگ فقط `google.com` می‌بینه و اجازه‌ی عبور می‌ده، در پشت صحنه یه رله‌ی Google Apps Script سایت واقعی رو برات می‌گیره و برمی‌گردونه. اگه قبلاً می‌خواستی این پروکسی رو دستی نصب کنی، باید همه چیز رو خودت انجام می‌دادی. GDFP همه‌ی اون مراحل رو تو یه منوی ساده جمع کرده.

---

## پیش‌نیازها

- اوبونتو ۲۲.۰۴ یا بالاتر
- دسترسی root یا sudo
- یه حساب Google رایگان (برای حالت پیش‌فرض)
- اتصال اینترنت

---
<div dir="rtl" align="right">

## نصب سریع

</div>

```bash
wget -O gdfp.sh https://raw.githubusercontent.com/Dnt3e/GDFP/main/gdfp.sh
chmod +x gdfp.sh
sudo bash gdfp.sh
```

<div dir="rtl" align="right">


## بعد از نصب

وقتی پروکسی داره روی `127.0.0.1:8085` اجرا می‌شه مرورگرت رو روی HTTP Proxy با این آدرس و پورت تنظیم کن. برای اینکه خطای امنیتی HTTPS نگیری هم باید گواهی CA رو نصب کنی؛ برنامه اولین بار خودکار این کار رو می‌کنه، اگه نشد این دستور رو بزن:

</div>

```bash
cd /opt/gdfp
python3 main.py --install-cert
```

<div dir="rtl" align="right">

---

## مشکلات رایج

مرورگر خطای امنیتی می‌ده یعنی گواهی CA نصب نشده — دستور بالا رو اجرا کن. اگه خطای `unauthorized` گرفتی یعنی `auth_key` در `config.json` با `AUTH_KEY` توی `Code.gs` فرق داره. اگه دانلود پروژه ناموفق بود و به GitHub دسترسی نداری، فایل ZIP رو دستی کنار `gdfp.sh` بذار. اگه سرعت پایینه چند تا `Code.gs` جداگانه deploy کن و آیدیشون رو توی آرایه‌ی `script_ids` بذار.

---

## ساختار فایل‌ها بعد از نصب

| مسیر | توضیح |
|---|---|
| `/opt/gdfp/` | پوشه‌ی نصب پروژه |
| `/opt/gdfp/config.json` | فایل تنظیمات |
| `/opt/gdfp/xray_outbound.json` | کانفیگ Xray (بعد از گزینه ۳) |
| `/etc/systemd/system/gdfp.service` | سرویس systemd |
| `/var/log/gdfp.log` | فایل لاگ |

---

## لایسنس

این اسکریپت بر اساس پروژه‌ی اصلی [MasterHttpRelayVPN](https://github.com/masterking32/MasterHttpRelayVPN) ساخته شده که تحت لایسنس MIT منتشر شده.

> این ابزار صرفاً برای مقاصد آموزشی و تحقیقاتی ارائه شده. استفاده از آن در قالب قوانین کشور خودت مسئولیت خودته.

</div>
