const sgMail = require('@sendgrid/mail')
sgMail.setApiKey(process.env.SENDGRID_API_KEY)

async function processMessageAsync(payload) {
  try {
    console.log(`Processing message ${payload.body}`);
    const message = JSON.parse(payload.body).Message;

    console.log(`Message content: ${message}`);

    const { id, email, doctor, pacient, date, start, end } = JSON.parse(message);

    const msg = {
      subject: "Health&Med - Nova consulta agendada",
      from: process.env.SENDGRID_EMAIL,
      to: email,
      templateId: process.env.SENDGRID_APPOINTMENT_CREATED_TEMPLATE_ID,
      dynamicTemplateData: {
        id,
        doctor,
        pacient,
        date,
        start,
        end,
      },
    };

    await sgMail
      .send(msg)
      .then(() => console.log(`Email sent to appointment with id: ${id}`))
      .catch((error) => {
        console.error(`Error sending email to appointment with id: ${id}`);
        console.error(error)
      })
  } catch (err) {
    console.error(`Error processing message ${payload?.Message}`);
    console.error(err);
    throw err;
  }
}

exports.handler = async (event, context) => {
  for (const message of event.Records) {
    await processMessageAsync(message)
  }
};
