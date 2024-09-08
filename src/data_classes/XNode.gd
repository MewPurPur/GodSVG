# Abstract base class for XML nodes.
class_name XNode extends RefCounted

var xid: PackedInt32Array

var _parent: WeakRef = null
var parent: Element:
	get():
		if _parent != null:
			return _parent.get_ref()
		return null
	set(new_value):
		_parent = weakref(new_value)

var _svg: WeakRef = null
var svg: ElementSVG:
	get():
		if _svg != null:
			return _svg.get_ref()
		return null
	set(new_value):
		_svg = weakref(new_value)

var _root: WeakRef = null
var root: ElementRoot:
	get():
		if _root != null:
			return _root.get_ref()
		return null
	set(new_value):
		_root = weakref(new_value)

# Overridden only in Element. In other XNodes, it does nothing.
func propagate_xid_correction() -> void:
	return
