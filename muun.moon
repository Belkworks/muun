[[-----------------------------------------------------------------
-- muun - moonscript compatible class implementation

-- Copyright 2019, 2021 megagrump@pm.me
-- License: MIT. See LICENSE for details
-----------------------------------------------------------------]]

wrap = (any, key) ->
	return any unless (type any) == 'function'
	(...) =>
		cur = @__fn
		@__fn = key
		r = { any @, ... }
		@__fn = cur
		unpack r

setup = (__name, __parent, __base) ->
	mt =
		__call: (...) =>
			obj = setmetatable({}, __base)
			@.__fn = 'new'
			@.__init(obj, ...)
			@.__fn = nil
			obj
		__index: __base
		__newindex: (key, value) => __base[key] = value

	__base.new or= =>

	cls = setmetatable({
		__init: (...) -> __base.new(...)
		:__name
		:__base
		:__parent
	}, mt)

	with __base
		.__class, .__index = cls, __base

	old = __base.__index
	__base.__index = (K) =>
		if K == 'super'
			__parent[assert @__fn, 'couldnt find super!']
		else wrap old[K], K

	cls

super = (parent) ->
	setmetatable({}, {
		__call: (this, ...) => parent.__init(this, ...)
		__index: parent
	})

extend = (name, parent, base) ->
	setmetatable(base, parent.__base)

	cls = setup(name, parent, base)
	cls.__super = super(parent)

	parent.__inherited(parent, cls) if parent.__inherited
	cls

(name, parentOrBase, base) ->
	error("Invalid class name") if type(name) ~= 'string'

	parent = parentOrBase if type(parentOrBase) == 'table' and parentOrBase.__class
	base = not parent and parentOrBase or base or {}
	if parent
		extend(name, parent, base)
	else
		setup(name, nil, base)
