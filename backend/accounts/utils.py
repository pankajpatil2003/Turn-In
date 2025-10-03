from django.core.mail import send_mail
from django.conf import settings

def send_otp_email(email_address, otp_code):
    """
    Sends the generated OTP code to the user's email address.
    
    Args:
        email_address (str): The recipient's email address.
        otp_code (str): The 6-digit OTP code to send.
    
    Returns:
        bool: True if the email was sent successfully, False otherwise.
    """
    subject = 'Your Verification Code for Turn-In Registration'
    
    # Custom email message content
    message_body = f"""
    Dear Student,

    Thank you for registering for Turn-In!

    Your verification code (OTP) is: {otp_code}

    This code is valid for 10 minutes. Please enter it on the registration screen to complete your account setup.

    If you did not request this code, please ignore this email.

    Best regards,
    The Turn-In Team
    """

    try:
        send_mail(
            subject,
            message_body,
            settings.DEFAULT_FROM_EMAIL,
            [email_address],
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending email to {email_address}: {e}")
        return False