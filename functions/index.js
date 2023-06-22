const { google } = require('googleapis');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

const run = google.run('v1');

const secretManger = new SecretManagerServiceClient();

exports.createRevision = async (event, _context) => {
  const decodedEvent = decodeEventMessage(event);

  console.log('Event: ', decodedEvent);

  const { tag, action } = decodedEvent;

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
    gcsPrivateKeySecretName,
  } = getEnv();

  const gcsPrivateKey = await getSecret(gcsPrivateKeySecretName);

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

function decodeEventMessage(event) {
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

  const targets = ['docker.pkg.dev', 'turborepo-remote-cache'];

  return targets.some((target) => tag.includes(target));
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
    gcsPrivateKeySecretName: process.env.GCS_PRIVATE_KEY_SECRET_NAME,
  };
}

async function getSecret(secretName) {
  const { projectId } = getEnv();
  const [version] = await secretManger.accessSecretVersion({
    name: `projects/${projectId}/secrets/${secretName}/versions/latest`,
  });

  // Extract the payload as a string.
  const payload = version.payload.data.toString('utf8');

  return payload;
}
