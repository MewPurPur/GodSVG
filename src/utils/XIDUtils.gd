class_name XIDUtils extends RefCounted

# [1] > [1, 2] > [1, 0] > [0]
static func compare(xid1: PackedInt32Array, xid2: PackedInt32Array) -> bool:
	var smaller_xid_size := mini(xid1.size(), xid2.size())
	for i in smaller_xid_size:
		if xid1[i] < xid2[i]:
			return true
		elif xid1[i] > xid2[i]:
			return false
	return xid1.size() > smaller_xid_size

static func compare_reverse(xid1: PackedInt32Array, xid2: PackedInt32Array) -> bool:
	return compare(xid2, xid1)

# Indirect parent, i.e. ancestor. Passing the root element as parent will return false.
static func is_parent(parent: PackedInt32Array, child: PackedInt32Array) -> bool:
	if parent.is_empty():
		return false
	var parent_size := parent.size()
	if parent_size >= child.size():
		return false
	
	for i in parent_size:
		if parent[i] != child[i]:
			return false
	return true

static func is_parent_or_self(parent: PackedInt32Array,
child: PackedInt32Array) -> bool:
	return is_parent(parent, child) or parent == child

static func get_parent_xid(xid: PackedInt32Array) -> PackedInt32Array:
	var parent_xid := xid.duplicate()
	parent_xid.resize(xid.size() - 1)
	return parent_xid

static func are_siblings(xid1: PackedInt32Array, xid2: PackedInt32Array) -> bool:
	if xid1.size() != xid2.size():
		return false
	for i in xid1.size() - 1:
		if xid1[i] != xid2[i]:
			return false
	return true

# Filter out all descendants.
static func filter_descendants(xids: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	var new_xids: Array[PackedInt32Array] = xids.duplicate()
	new_xids.sort_custom(compare_reverse)
	# Linear scan to filter out the descendants.
	var last_accepted := new_xids[0]
	var i := 1
	while i < new_xids.size():
		var xid := new_xids[i]
		if is_parent_or_self(last_accepted, xid):
			new_xids.remove_at(i)
		else:
			last_accepted = new_xids[i]
			i += 1
	return new_xids

# Not typed to Array[PackedInt32Array] because typed arrays were annoying.
static func are_xid_lists_same(xid_list_1: Array, xid_list_2: Array) -> bool:
	if xid_list_1.size() != xid_list_2.size():
		return false
	
	for xid in xid_list_1:
		if not xid in xid_list_2:
			return false
	return true
