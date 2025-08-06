## XID stands for XML Node ID. These IDs take the form of a PackedInt32Array with indices.
## For example, if an XML node is the third child of the first element, its XID is [0, 2].
## This class provides utilities for working with XIDs.
@abstract class_name XIDUtils

# [1] > [1, 2] > [1, 0] > [0]
static func compare(xid1: PackedInt32Array, xid2: PackedInt32Array) -> bool:
	var smaller_xid_size := mini(xid1.size(), xid2.size())
	for i in smaller_xid_size:
		if xid1[i] == xid2[i]:
			continue
		return xid1[i] < xid2[i]
	return xid1.size() > smaller_xid_size

static func compare_reverse(xid1: PackedInt32Array, xid2: PackedInt32Array) -> bool:
	return compare(xid2, xid1)

## Checks if a XID describes an element that's an ancestor to another's XID.
## Passing the root element as ancestor returns false.
static func is_ancestor(ancestor: PackedInt32Array, child: PackedInt32Array) -> bool:
	if ancestor.is_empty():
		return false
	var ancestor_size := ancestor.size()
	if ancestor_size >= child.size():
		return false
	
	for i in ancestor_size:
		if ancestor[i] != child[i]:
			return false
	return true

## Checks if a XID describes an element that's an ancestor to another's XID.
## Also returns true if the two elements are the same. Passing the root element as ancestor returns false.
static func is_ancestor_or_self(ancestor: PackedInt32Array, child: PackedInt32Array) -> bool:
	if ancestor.is_empty():
		return false
	var ancestor_size := ancestor.size()
	if ancestor_size > child.size():
		return false
	
	for i in ancestor_size:
		if ancestor[i] != child[i]:
			return false
	return true

## Returns the XID representing the parent of the node represented by the passed XID.
static func get_parent_xid(xid: PackedInt32Array) -> PackedInt32Array:
	var parent_xid := xid.duplicate()
	parent_xid.resize(xid.size() - 1)
	return parent_xid

## Returns true if the two XIDs represent sibling nodes or the same node.
static func are_siblings_or_same(xid1: PackedInt32Array, xid2: PackedInt32Array) -> bool:
	if xid1.size() != xid2.size():
		return false
	for i in xid1.size() - 1:
		if xid1[i] != xid2[i]:
			return false
	return true

## Filters out from the passed array of XIDs all of the ones that are descendants of another XID. 
static func filter_descendants(xids: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	var new_xids: Array[PackedInt32Array] = xids.duplicate()
	new_xids.sort_custom(compare_reverse)
	# Linear scan to filter out the descendants.
	var last_accepted := new_xids[0]
	var i := 1
	while i < new_xids.size():
		var xid := new_xids[i]
		if is_ancestor_or_self(last_accepted, xid):
			new_xids.remove_at(i)
		else:
			last_accepted = new_xids[i]
			i += 1
	return new_xids

# Not typed to Array[PackedInt32Array] because typed arrays were annoying.
## Returns true if the two passed arrays of XIDs contain the same XIDs.
static func are_xid_lists_same(xid_list_1: Array, xid_list_2: Array) -> bool:
	if xid_list_1.size() != xid_list_2.size():
		return false
	
	for xid in xid_list_1:
		if not xid in xid_list_2:
			return false
	return true
