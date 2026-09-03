Hey Trevor,

Following up on the datastore capacity issue from the recent builds — wanted to loop you in on the plan.

The ask: we want to add a pre-build storage capacity check to create_vm so we stop landing builds on datastores that don't actually have room, before it gets to the point of needing an emergency space add mid-build.

I went through datastore.yml.j2 and create_vm.yml to see exactly what your existing logic does today:
- If host_specification.datastore matches a standalone datastore name, it's used directly (this is the VSAN/local path).
- Otherwise it's treated as a datastore-cluster name — you pull the cluster's member datastores, sort by freeSpace, and take the one with the most free space.

What I don't see anywhere is a check of that freeSpace against how much the build actually needs — it just always picks the biggest-free-space member, regardless of whether that's enough for a multi-TB build. And since disks.yml.j2 pins every disk (OS + extra storage) to that same single datastore, the real number to check against is the full sum of requested disk sizes for the VM, not just the OS disk.

Plan is to add a validation step right after vmware_datastore_info runs (before the __datastore fact gets set) that sums the requested disk sizes and compares against available space, and fails/falls back if it won't fit. Want to also handle VSAN and non-shared/local datastores with their own threshold logic since those behave differently from datastore clusters (SDRS rebalancing after the fact, etc.).

Wanted to check with you before building on top of this — does that match how you understand the current selection logic, or is there something else already happening that I'm missing? Also happy to combine efforts if you were already thinking about tackling this.



Hey Charles,

Wanted to share what I found digging into the datastore selection logic in create_vm, following up on the capacity issue we discussed.

What Trevor's existing logic does today (datastore.yml.j2): if the target is a standalone datastore, it's used as-is; if it's a datastore cluster, it pulls the member datastores and picks whichever has the most free space. That's it — there's no check of whether that free space is actually enough for the build. And since all of a VM's disks (OS + extra storage) get pinned to that same resolved datastore, the real requirement is the sum of everything being provisioned, not just the boot disk.

That gap is basically why we saw what we saw — it kept picking the largest-available datastore, which then got run down fast by back-to-back multi-TB builds.

Plan is to add a pre-build check before the VM create task runs: sum up the requested disk sizes, compare against available space on the datastore/cluster the template would pick, and stop the build (or fall back) if it won't fit. We'll likely need separate logic/thresholds for VSAN, non-shared/local storage, and datastore clusters, since datastore clusters have the added wrinkle of SDRS rebalancing volumes after a build lands.

I'm looping Trevor in to confirm my read of his logic before we start building on top of it. Will keep you posted.
