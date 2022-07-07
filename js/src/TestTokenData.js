export default {
  methods: ["token", "password"],
  user: {
    domain: {
      id: "2bac466eed364d8a92e477459e908736",
      name: "monsoon3",
    },
    id: "a965abad2ee0de10335a60d568148d2bef51030e00b0e7b1d5376a3b934aa53e",
    name: "D064310",
    password_expires_at: "2022-08-14T11:03:35.997068",
  },
  audit_ids: ["0rl0Fh98S5SO9DaTWvDoVQ", "ipgFPPb4RkKfRt2AThdZpg"],
  expires_at: "2022-07-06T16:56:59.000000Z",
  issued_at: "2022-07-06T11:36:41.000000Z",
  project: {
    domain: {
      id: "2bac466eed364d8a92e477459e908736",
      name: "monsoon3",
    },
    id: "e9141fb24eee4b3e9f25ae69cda31132",
    name: "cc-demo",
  },
  is_domain: false,
  roles: [
    {
      id: "a2beaae1aae8445e979f42c565b35075",
      name: "resource_viewer",
    },
    {
      id: "2dacc66a44ed4292a64f0d2b1d282735",
      name: "email_admin",
    },
    {
      id: "e2b547ebedc442dd935c04dbb47ad64f",
      name: "audit_viewer",
    },
  ],
  is_admin_project: false,
  catalog: [
    {
      endpoints: [
        {
          id: "7a890e6b5c3c43579094dbe76dbb7ef7",
          interface: "public",
          region_id: "qa-de-1",
          url: "https://volume-3.qa-de-1.cloud.sap:443/v2/e9141fb24eee4b3e9f25ae69cda31132",
          region: "qa-de-1",
        },
        {
          id: "7e5d084fc715490abe67e683058d275d",
          interface: "internal",
          region_id: "qa-de-1",
          url: "http://cinder-api.monsoon3.svc.kubernetes.qa-de-1.cloud.sap:8776/v2/e9141fb24eee4b3e9f25ae69cda31132",
          region: "qa-de-1",
        },
        {
          id: "d05310e2ad3e4a61b28cb1fd9e5b83ae",
          interface: "admin",
          region_id: "qa-de-1",
          url: "http://cinder-api.monsoon3.svc.kubernetes.qa-de-1.cloud.sap:8776/v2/e9141fb24eee4b3e9f25ae69cda31132",
          region: "qa-de-1",
        },
      ],
      id: "0125ce0816cc4a8f986ac15db18c3dd9",
      type: "volumev2",
      name: "cinderv2",
    },
    {
      endpoints: [
        {
          id: "04f6a4b664a9473987b8706478fd1ec0",
          interface: "public",
          region_id: "qa-de-1",
          url: "https://hermes.qa-de-1.cloud.sap/v1",
          region: "qa-de-1",
        },
        {
          id: "1993dc22406042a88436ac92452704c0",
          interface: "public",
          region_id: "staging",
          url: "https://hermes.staging.cloud.sap/v1",
          region: "staging",
        },
      ],
      id: "0608b418336c4b0a9f85c3eeb1e3615c",
      type: "audit-data",
      name: "hermes",
    },
  ],
}
