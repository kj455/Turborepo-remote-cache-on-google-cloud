const { google } = require('googleapis');
const run = google.run('v1');

exports.createRevision = async (event, _context) => {
  const parsedEvent = parseEventMessage(event);

  console.log('Event: ', parsedEvent);

  const { tag, action } = parsedEvent;

  if (!validateTag(tag) || !validateAction(action)) {
    console.error('Skipped to create revision');
    return;
  }

  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });

  const authClient = await auth.getClient();
  google.options({ auth: authClient });

  const {
    projectId,
    location,
    serviceId,
    turboToken,
    gcsBucketName,
    gcsClientEmail,
    gcsPrivateKey,
  } = getEnv();

  const request = {
    name: `projects/${projectId}/locations/${location}/services/${serviceId}`,
    requestBody: {
      apiVersion: 'serving.knative.dev/v1',
      kind: 'Service',
      metadata: {
        name: serviceId,
        namespace: projectId,
      },
      spec: {
        template: {
          spec: {
            containers: [
              {
                image: tag,
                env: [
                  {
                    name: 'NODE_ENV',
                    value: 'production',
                  },
                  {
                    name: 'TURBO_TOKEN',
                    value: turboToken,
                  },
                  {
                    name: 'STORAGE_PROVIDER',
                    value: 'google-cloud-storage',
                  },
                  {
                    name: 'GCS_PROJECT_ID',
                    value: projectId,
                  },
                  {
                    name: 'STORAGE_PATH',
                    value: gcsBucketName,
                  },
                  {
                    name: 'GCS_CLIENT_EMAIL',
                    value: gcsClientEmail,
                  },
                  {
                    name: 'GCS_PRIVATE_KEY',
                    value: gcsPrivateKey,
                  },
                ],
              },
            ],
          },
        },
      },
    },
  };

  try {
    const response = await run.projects.locations.services.replaceService(
      request
    );
    console.log(
      `Created revision: ${response.data.status.latestCreatedRevisionName}`
    );
  } catch (error) {
    console.error(`Failed to create revision: ${error}`);
  }
};

function parseEventMessage(event) {
  const pubSubMessage = event.data;
  const decodedData = JSON.parse(
    Buffer.from(pubSubMessage, 'base64').toString()
  );

  return decodedData;
}

function validateTag(tag) {
  if (tag == null) {
    return false;
  }

  return tag.includes('docker.pkg.dev');
}

function validateAction(action) {
  return action === 'INSERT';
}

function getEnv() {
  return {
    projectId: process.env.PROJECT_ID,
    location: process.env.LOCATION,
    serviceId: process.env.SERVICE_ID,
    turboToken: process.env.TURBO_TOKEN,
    gcsBucketName: process.env.GCS_BUCKET_NAME,
    gcsClientEmail: process.env.GCS_CLIENT_EMAIL,
    gcsPrivateKey: process.env.GCS_PRIVATE_KEY,
  };
}
