db = db.getSiblingDB("admin");
db.auth("root", "StrongRootPassword");

db = db.getSiblingDB("unifi");
db.createUser({
  user: "unifi",
  pwd: "UnifiAppPassword",
  roles: [
    { role: "dbOwner", db: "unifi" },
    { role: "dbOwner", db: "unifi_stat" },
    { role: "dbOwner", db: "unifi_audit" },
    { role: "dbOwner", db: "unifi_restore" },
    { role: "clusterMonitor", db: "admin" }
  ]
});
