import { defineConfig } from 'cypress'

import conf from '@open-condo/config'

export default defineConfig({
    e2e: {
        baseUrl: conf['SERVER_URL'],
        projectId: 'dc36jj',
        videoCompression: 15,
        waitForAnimations: true,
        defaultCommandTimeout: 10000,
        retries: 3,
        setupNodeEvents (on, config) {
            // eslint-disable-next-line import/order
            return require('./plugins/index.js')(on, config)
        },
        env: {
            supportPassword: conf['CYPRESS_SERVER_SUPPORT_PASSWORD'],
            supportEmail: conf['CYPRESS_SERVER_SUPPORT_EMAIL'],
        },
        requestTimeout: 10000,
        numTestsKeptInMemory: 1,
    },
})
