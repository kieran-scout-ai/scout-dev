"""
title: Azure Email Sender
author: open-webui
author_url: https://github.com/open-webui
funding_url: https://github.com/open-webui
version: 0.1.0
requirements: azure-communication-email
"""

import os
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field
from azure.communication.email import EmailClient
from azure.core.exceptions import HttpResponseError


class Tools:
    class Valves(BaseModel):
        connection_string: str = Field(
            default="", description="Azure Communication Services connection string"
        )
        sender_email: str = Field(
            default="", description="Verified sender email address"
        )
        max_recipients: int = Field(
            default=10, description="Maximum number of recipients per email"
        )
        enable_html: bool = Field(default=True, description="Allow HTML email content")

    def __init__(self):
        self.valves = self.Valves()
        self.email_client = None
        self._initialize_client()

    def _initialize_client(self):
        """Initialize the Azure email client with connection string"""
        connection_string = self.valves.connection_string or os.getenv(
            "AZURE_COMMUNICATION_CONNECTION_STRING"
        )

        if connection_string:
            try:
                self.email_client = EmailClient.from_connection_string(
                    connection_string
                )
            except Exception as e:
                print(f"Failed to initialize Azure email client: {e}")
        else:
            print("Azure Communication Services connection string not provided")

    def send_email(
        self,
        to_recipients: str,
        subject: str,
        body: str,
        cc_recipients: Optional[str] = None,
        bcc_recipients: Optional[str] = None,
        is_html: Optional[bool] = False,
        __user__: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Send an email using Azure Communication Services.

        Args:
            to_recipients: Comma-separated list of recipient email addresses
            subject: Email subject line
            body: Email body content
            cc_recipients: Comma-separated list of CC email addresses (optional)
            bcc_recipients: Comma-separated list of BCC email addresses (optional)
            is_html: Whether the body content is HTML (default: False)
            __user__: User information (automatically provided by Open WebUI)

        Returns:
            Success message with message ID or error message
        """

        # Re-initialize client if valves changed
        if not self.email_client:
            self._initialize_client()

        if not self.email_client:
            return "❌ Error: Azure email client not initialized. Please check connection string."

        # Get sender email from valves or environment
        sender_address = self.valves.sender_email or os.getenv("AZURE_SENDER_EMAIL")
        if not sender_address:
            return "❌ Error: Sender email address not configured."

        try:
            # Parse recipient lists
            to_list = [
                email.strip() for email in to_recipients.split(",") if email.strip()
            ]
            cc_list = (
                [
                    email.strip()
                    for email in cc_recipients.split(",")
                    if cc_recipients and email.strip()
                ]
                if cc_recipients
                else []
            )
            bcc_list = (
                [
                    email.strip()
                    for email in bcc_recipients.split(",")
                    if bcc_recipients and email.strip()
                ]
                if bcc_recipients
                else []
            )

            # Validate recipients
            if not to_list:
                return "❌ Error: At least one recipient email address is required"

            total_recipients = len(to_list) + len(cc_list) + len(bcc_list)
            if total_recipients > self.valves.max_recipients:
                return f"❌ Error: Too many recipients. Maximum allowed: {self.valves.max_recipients}"

            # Check HTML permission
            if is_html and not self.valves.enable_html:
                return "❌ Error: HTML emails are disabled in configuration"

            # Prepare email message
            email_content = {
                "content": {
                    "subject": subject,
                    "plainText": body if not is_html else None,
                    "html": body if is_html else None,
                },
                "recipients": {
                    "to": [{"address": email} for email in to_list],
                },
                "senderAddress": sender_address,
            }

            # Add CC recipients if provided
            if cc_list:
                email_content["recipients"]["cc"] = [
                    {"address": email} for email in cc_list
                ]

            # Add BCC recipients if provided
            if bcc_list:
                email_content["recipients"]["bcc"] = [
                    {"address": email} for email in bcc_list
                ]

            # Send the email
            poller = self.email_client.begin_send(email_content)
            result = poller.result()

            user_info = f" (sent by {__user__.get('name', 'user')})" if __user__ else ""
            return f"✅ Email sent successfully{user_info}! Message ID: {result['id']}"

        except HttpResponseError as e:
            return f"❌ Azure Communication Services error: {str(e)}"
        except Exception as e:
            return f"❌ Error sending email: {str(e)}"

    def send_html_email(
        self,
        to_recipients: str,
        subject: str,
        html_body: str,
        cc_recipients: Optional[str] = None,
        bcc_recipients: Optional[str] = None,
        __user__: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Send an HTML email using Azure Communication Services.

        Args:
            to_recipients: Comma-separated list of recipient email addresses
            subject: Email subject line
            html_body: HTML email body content
            cc_recipients: Comma-separated list of CC email addresses (optional)
            bcc_recipients: Comma-separated list of BCC email addresses (optional)
            __user__: User information (automatically provided by Open WebUI)

        Returns:
            Success message with message ID or error message
        """

        return self.send_email(
            to_recipients=to_recipients,
            subject=subject,
            body=html_body,
            cc_recipients=cc_recipients,
            bcc_recipients=bcc_recipients,
            is_html=True,
            __user__=__user,
        )

    def test_connection(self, __user__: Optional[Dict[str, Any]] = None) -> str:
        """
        Test the Azure email service connection and configuration.

        Returns:
            Status message about the connection and configuration
        """
        try:
            print("Testing Azure email connection...")

            # Check if dependencies are available
            try:
                from azure.communication.email import EmailClient

                print("✓ azure-communication-email package is available")
            except ImportError as e:
                return f"❌ Missing dependency: azure-communication-email package not installed. Error: {e}"

            # Check connection string
            connection_string = self.valves.connection_string or os.getenv(
                "AZURE_COMMUNICATION_CONNECTION_STRING"
            )
            if not connection_string:
                return "❌ No connection string found in valves or AZURE_COMMUNICATION_CONNECTION_STRING environment variable"

            print("✓ Connection string found")

            # Check sender email
            sender_address = self.valves.sender_email or os.getenv("AZURE_SENDER_EMAIL")
            if not sender_address:
                return "❌ No sender email found in valves or AZURE_SENDER_EMAIL environment variable"

            print(f"✓ Sender email configured: {sender_address}")

            # Try to initialize client
            if self._initialize_client():
                return f"✅ Azure email service is properly configured and ready to use.\nSender: {sender_address}\nMax recipients: {self.valves.max_recipients}\nHTML enabled: {self.valves.enable_html}"
            else:
                return "❌ Failed to initialize Azure email client. Check your connection string."

        except Exception as e:
            return f"❌ Error testing connection: {str(e)}"

    def send_notification_email(
        self,
        to_recipients: str,
        notification_type: str,
        message: str,
        details: Optional[str] = None,
        priority: Optional[str] = "normal",
        __user__: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Send a formatted notification email with professional styling.

        Args:
            to_recipients: Comma-separated list of recipient email addresses
            notification_type: Type of notification (e.g., "Alert", "Info", "Warning")
            message: Main notification message
            details: Additional details (optional)
            priority: Email priority - "low", "normal", or "high" (optional)
            __user__: User information (automatically provided by Open WebUI)

        Returns:
            Success message with message ID or error message
        """

        # Priority-based subject formatting
        priority_prefix = {"high": "🚨 [URGENT]", "normal": "📧", "low": "ℹ️"}.get(
            priority.lower(), "📧"
        )

        subject = (
            f"{priority_prefix} [{notification_type}] Notification from Open WebUI"
        )

        # Color scheme based on notification type
        color_scheme = {
            "alert": "#dc3545",
            "warning": "#ffc107",
            "info": "#17a2b8",
            "success": "#28a745",
            "error": "#dc3545",
        }.get(notification_type.lower(), "#007bff")

        # Create a formatted HTML body
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{notification_type} Notification</title>
        </head>
        <body style="margin: 0; padding: 0; background-color: #f4f4f4; font-family: Arial, sans-serif;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 0;">
                <div style="background-color: {color_scheme}; padding: 20px; text-align: center;">
                    <h1 style="color: white; margin: 0; font-size: 24px;">{notification_type}</h1>
                </div>
                <div style="padding: 30px;">
                    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid {color_scheme}; margin-bottom: 20px;">
                        <p style="color: #333; font-size: 16px; line-height: 1.6; margin: 0;">{message}</p>
                    </div>
                    {f'''
                    <div style="background-color: #fff; padding: 20px; border: 1px solid #e9ecef; border-radius: 8px; margin-bottom: 20px;">
                        <h3 style="color: #495057; margin-top: 0; font-size: 16px;">Additional Details:</h3>
                        <p style="color: #6c757d; font-size: 14px; line-height: 1.5; margin: 0;">{details}</p>
                    </div>
                    ''' if details else ''}
                    <div style="text-align: center; padding-top: 20px; border-top: 1px solid #e9ecef;">
                        <p style="color: #6c757d; font-size: 12px; margin: 0;">
                            This notification was automatically sent from Open WebUI
                            {f" by {__user__.get('name', 'System')}" if __user__ else ""}
                        </p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """

        return self.send_html_email(
            to_recipients=to_recipients,
            subject=subject,
            html_body=html_body,
            __user__=__user,
        )
