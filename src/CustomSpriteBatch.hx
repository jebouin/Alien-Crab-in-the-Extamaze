package ;

import h2d.Tile;
import h2d.Drawable;
import h2d.RenderContext;
import h2d.impl.BatchDrawState;

private class ElementsIterator {
	var e : BatchElement;
	public inline function new(e) {
		this.e = e;
	}
	public inline function hasNext() {
		return e != null;
	}
	public inline function next() {
		var n = e;
		e = @:privateAccess e.next;
		return n;
	}
}

@:allow(CustomSpriteBatch)
class BatchElement {
	public var x : Float = 0;
	public var y : Float = 0;
	public var scale(never,set) : Float;
	public var scaleX : Float = 1;
	public var scaleY : Float = 1;
	public var rotation : Float = 0;
	public var r : Float = 1;
	public var g : Float = 1;
	public var b : Float = 1;
	public var a : Float = 1;
	public var t : Tile;
	public var alpha(get,set) : Float;
	public var visible : Bool = true;
	public var batch(default, null) : CustomSpriteBatch;
	var prev : BatchElement;
	var next : BatchElement;

	public function new(t : Tile) {
		this.t = t;
	}

	inline function set_scale(v) {
		return scaleX = scaleY = v;
	}

	inline function get_alpha() {
		return a;
	}

	inline function set_alpha(v) {
		return a = v;
	}

	function update(dt:Float) {
		return true;
	}

	public function remove() {
		if(batch != null) {
            batch.delete(this);
        }
	}

	public function toString() {
		return "     " + y + " " + x + " prev=" + (prev == null ? "null" : "" + prev.x) + "  next=" + (next == null ? "null" : "" + next.x);
	}
}

// Custom fixed-time SpriteBatch with ysort
class CustomSpriteBatch extends Drawable {
	public var tile : Tile;
	public var hasRotationScale : Bool = false;
	public var hasUpdate : Bool = false;
	public var elementCount(default, null) : Int = 0;
	var head : BatchElement;
	var tail : BatchElement;
	var tmpBuf : hxd.FloatBuffer;
	var buffer : h3d.Buffer;
	var state : BatchDrawState;
	var empty : Bool;

	public function new(t, ?parent) {
		super(parent);
		tile = t;
		state = new BatchDrawState();
	}

	public function add(e:BatchElement,before=false) {
		e.batch = this;
		if(head == null) {
			head = tail = e;
			e.prev = e.next = null;
		} else if(before) {
			e.prev = null;
			e.next = head;
			head.prev = e;
			head = e;
		} else {
			tail.next = e;
			e.prev = tail;
			e.next = null;
			tail = e;
		}
		elementCount++;
		return e;
	}

	public function clear() {
		head = tail = null;
		flush();
		elementCount = 0;
	}

	public function alloc(t : Tile) : BatchElement {
		return add(new BatchElement(t));
	}

	@:allow(BatchElement)
	function delete(e : BatchElement) {
		if(e.prev == null) {
			if(head == e) head = e.next;
		} else {
			e.prev.next = e.next;
        }
		if(e.next == null) {
			if(tail == e) tail = e.prev;
		} else {
			e.next.prev = e.prev;
        }
		e.batch = null;
		elementCount--;
	}

	override function sync(ctx) {
		super.sync(ctx);
		flush();
	}

    public function update(dt:Float) {
        if(!hasUpdate) return;
        var e = head;
        while(e != null) {
            if(!e.update(dt)) {
                e.remove();
            }
            e = e.next;
        }
    }

	override function getBoundsRec(relativeTo, out, forSize) {
		super.getBoundsRec(relativeTo, out, forSize);
		var e = head;
		while(e != null) {
			var t = e.t;
			if(hasRotationScale) {
				var ca = Math.cos(e.rotation), sa = Math.sin(e.rotation);
				var hx = t.width, hy = t.height;
				var px = t.dx * e.scaleX, py = t.dy * e.scaleY;
				var x, y;

				x = px * ca - py * sa + e.x;
				y = py * ca + px * sa + e.y;
				addBounds(relativeTo, out, x, y, 1e-10, 1e-10);

				var px = (t.dx + hx) * e.scaleX, py = t.dy * e.scaleY;
				x = px * ca - py * sa + e.x;
				y = py * ca + px * sa + e.y;
				addBounds(relativeTo, out, x, y, 1e-10, 1e-10);

				var px = t.dx * e.scaleX, py = (t.dy + hy) * e.scaleY;
				x = px * ca - py * sa + e.x;
				y = py * ca + px * sa + e.y;
				addBounds(relativeTo, out, x, y, 1e-10, 1e-10);

				var px = (t.dx + hx) * e.scaleX, py = (t.dy + hy) * e.scaleY;
				x = px * ca - py * sa + e.x;
				y = py * ca + px * sa + e.y;
				addBounds(relativeTo, out, x, y, 1e-10, 1e-10);
			} else {
				addBounds(relativeTo, out, e.x + t.dx, e.y + t.dy, t.width, t.height);
            }
			e = e.next;
		}
	}

	function flush() {
		if(head == null) return;
		if(tmpBuf == null) tmpBuf = new hxd.FloatBuffer();
		var pos = 0;
		var e = head;
		var tmp = tmpBuf;
		var bufferVertices = 0;
		state.clear();
		while(e != null) {
			if(!e.visible) {
				e = e.next;
				continue;
			}
			var t = e.t;
			state.setTile(t);
			state.add(4);
			tmp.grow(pos + 8 * 4);
            @:privateAccess {
                if(hasRotationScale) {
                    var ca = Math.cos(e.rotation), sa = Math.sin(e.rotation);
                    var hx = t.width, hy = t.height;
                    var px = t.dx * e.scaleX, py = t.dy * e.scaleY;
                    tmp[pos++] = px * ca - py * sa + e.x;
                    tmp[pos++] = py * ca + px * sa + e.y;
                    tmp[pos++] = t.u;
                    tmp[pos++] = t.v;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                    var px = (t.dx + hx) * e.scaleX, py = t.dy * e.scaleY;
                    tmp[pos++] = px * ca - py * sa + e.x;
                    tmp[pos++] = py * ca + px * sa + e.y;
                    tmp[pos++] = t.u2;
                    tmp[pos++] = t.v;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                    var px = t.dx * e.scaleX, py = (t.dy + hy) * e.scaleY;
                    tmp[pos++] = px * ca - py * sa + e.x;
                    tmp[pos++] = py * ca + px * sa + e.y;
                    tmp[pos++] = t.u;
                    tmp[pos++] = t.v2;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                    var px = (t.dx + hx) * e.scaleX, py = (t.dy + hy) * e.scaleY;
                    tmp[pos++] = px * ca - py * sa + e.x;
                    tmp[pos++] = py * ca + px * sa + e.y;
                    tmp[pos++] = t.u2;
                    tmp[pos++] = t.v2;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                } else {
                    var sx = e.x + t.dx;
                    var sy = e.y + t.dy;
                    tmp[pos++] = sx;
                    tmp[pos++] = sy;
                    tmp[pos++] = t.u;
                    tmp[pos++] = t.v;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                    tmp[pos++] = sx + t.width + 0.1;
                    tmp[pos++] = sy;
                    tmp[pos++] = t.u2;
                    tmp[pos++] = t.v;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                    tmp[pos++] = sx;
                    tmp[pos++] = sy + t.height + 0.1;
                    tmp[pos++] = t.u;
                    tmp[pos++] = t.v2;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                    tmp[pos++] = sx + t.width + 0.1;
                    tmp[pos++] = sy + t.height + 0.1;
                    tmp[pos++] = t.u2;
                    tmp[pos++] = t.v2;
                    tmp[pos++] = e.r;
                    tmp[pos++] = e.g;
                    tmp[pos++] = e.b;
                    tmp[pos++] = e.a;
                }
            }
			e = e.next;
		}
		bufferVertices = pos>>3;
		if(buffer != null && !buffer.isDisposed()) {
			if(buffer.vertices >= bufferVertices){
				buffer.uploadFloats(tmpBuf, 0, bufferVertices);
				return;
			}
			buffer.dispose();
			buffer = null;
		}
		empty = bufferVertices == 0;
		if(bufferVertices > 0)
			buffer = h3d.Buffer.ofSubFloats(tmpBuf, bufferVertices, hxd.BufferFormat.H2D, [Dynamic]);
	}

	override function draw(ctx : RenderContext) {
		drawWith(ctx, this);
	}

	function drawWith(ctx:RenderContext, obj : Drawable) {
		if(head == null || buffer == null || buffer.isDisposed() || empty) return;
		if(!ctx.beginDrawBatchState(obj)) return;
		state.drawQuads(ctx, buffer);
	}

	public inline function isEmpty() {
		return head == null;
	}

	public inline function getElements() {
		return new ElementsIterator(head);
	}

	override function onRemove() {
		super.onRemove();
		if(buffer != null) {
			buffer.dispose();
			buffer = null;
		}
		state.clear();
	}

    public function ysort() {
        head = ysortRec(head);
    }

    function ysortRec(head:BatchElement) {
        if(head == null || head.next == null) return head;
        var mid = head, end = head.next;
        while(end != null && end.next != null) {
            mid = mid.next;
            end = end.next.next;
        }
        var left = head, right = mid.next;
        mid.next = null;
		right.prev = null;
        left = ysortRec(left);
        right = ysortRec(right);
        return merge(left, right);
    }

    function merge(left:BatchElement, right:BatchElement) : BatchElement {
		var head:BatchElement = null, tail:BatchElement = null;
		inline function add(e) {
			if(head == null) {
				head = tail = e;
			} else if(head == tail) {
				tail = e;
				head.next = tail;
				tail.prev = head;
			} else {
				tail.next = e;
				e.prev = tail;
				tail = e;
			}
		}
		while(left != null || right != null) {
			if(right == null) {
				add(left);
				left = left.next;
			} else if(left == null) {
				add(right);
				right = right.next;
			} else if((left.y < right.y) || (left.y == right.y && left.x < right.x)) {
				add(left);
				left = left.next;
			} else {
				add(right);
				right = right.next;
			}
		}
		this.tail = tail;
        return head;
    }
}