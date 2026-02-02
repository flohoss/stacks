module.exports = {
    platform: 'github',
    extends: ['config:recommended'],
    assignees: ['flohoss'],
    prHourlyLimit: 0,
    dependencyDashboard: false,
    onboarding: false,
    hostRules: [
        {
            hostType: 'docker',
            matchHost: 'docker.io',
            username: 'unjxde',
            password: String(process.env.RENOVATE_DOCKER_HUB_PASSWORD || ''),
        },
        {
            hostType: 'docker',
            matchHost: 'ghcr.io',
            username: 'flohoss',
            password: String(process.env.RENOVATE_GHCR_TOKEN || ''),
        },
    ],
    packageRules: [
        {
            matchDatasources: ['docker'],
            matchPackageNames: ['docker.io/valkey/valkey', 'ghcr.io/immich-app/postgres'],
            enabled: false,
        },
        {
            matchDatasources: ['docker'],
            matchPackageNames: ['redis'],
            allowedVersions: '7.x',
        },
        {
            matchDatasources: ['docker'],
            matchPackageNames: ['postgres'],
            allowedVersions: '17.x',
        },
        {
            matchDatasources: ['docker'],
            matchPackageNames: ['mariadb'],
            allowedVersions: '10.x',
        },
        {
            matchDatasources: ['docker'],
            matchPackageNames: ['mongo'],
            allowedVersions: '6.x',
        },
        {
            matchDatasources: ['docker'],
            matchPackageNames: ['ghcr.io/immich-app/immich-machine-learning', 'ghcr.io/immich-app/immich-server'],
            groupName: 'Immich',
            groupSlug: 'immich',
            separateMinorPatch: false,
            separateMultipleMajor: false,
        },
        {
            matchDatasources: ['docker'],
            pinDigests: true,
        },
    ],
};
