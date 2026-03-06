import { Resend } from 'resend';

let _resend: Resend | null = null;

function getResend(): Resend {
  if (!_resend) {
    if (!process.env.RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY environment variable is not set');
    }
    _resend = new Resend(process.env.RESEND_API_KEY);
  }
  return _resend;
}

interface SendReportEmailParams {
  to: string;
  reportUrl: string;
  pdfUrl?: string;
  packageName: string;
}

export async function sendReportEmail({ to, reportUrl, pdfUrl, packageName }: SendReportEmailParams) {
  const resend = getResend();
  const fromEmail = process.env.RESEND_FROM_EMAIL || 'reports@crainpainting.com';

  await resend.emails.send({
    from: `Crain Painting <${fromEmail}>`,
    to,
    subject: `Your ${packageName} Color Report is Ready`,
    html: `
      <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin-bottom: 8px;">Your Color Report is Ready</h1>
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 24px;">
          Your ${packageName} has been completed by our AI color analysis system,
          backed by expert color science and Benjamin Moore's professional palette.
        </p>

        <a href="${reportUrl}"
           style="display: inline-block; background-color: #13D4D4; color: #0f172a; padding: 14px 28px;
                  text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 16px;">
          View Your Report
        </a>

        ${pdfUrl ? `
          <p style="margin-top: 24px; color: #666; font-size: 14px;">
            <a href="${pdfUrl}" style="color: #0A8080;">Download PDF version</a>
          </p>
        ` : ''}

        <hr style="margin: 32px 0; border: none; border-top: 1px solid #eee;" />

        <p style="color: #999; font-size: 12px;">
          Paint Visualizer Color Report<br/>
          Expert consultation by Curt Crain, Crain Painting
        </p>
      </div>
    `,
  });
}
