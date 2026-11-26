"""Gửi email (OTP đặt lại mật khẩu). Không cấu hình SMTP thì chỉ ghi log."""

import logging
import smtplib
from email.message import EmailMessage

from app.core.config import settings

logger = logging.getLogger("chailish.email")


def send_email(to: str, subject: str, body: str) -> None:
    if not settings.SMTP_HOST:
        logger.warning("SMTP chưa cấu hình, bỏ qua gửi email tới %s: %s\n%s", to, subject, body)
        return

    msg = EmailMessage()
    msg["From"] = settings.SMTP_FROM
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as smtp:
        if settings.SMTP_USE_TLS:
            smtp.starttls()
        if settings.SMTP_USER:
            smtp.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        smtp.send_message(msg)


def send_password_reset_otp(to: str, full_name: str, otp: str) -> None:
    body = (
        f"Xin chào {full_name},\n\n"
        f"Mã OTP đặt lại mật khẩu ChaiLish của bạn là: {otp}\n"
        f"Mã có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút. "
        "Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.\n\n"
        "ChaiLish"
    )
    send_email(to, "[ChaiLish] Mã OTP đặt lại mật khẩu", body)
