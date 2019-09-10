
document.addEventListener('blankeLoaded',(e) => {
    let { Entity, Draw } = e.detail.Blanke;

    Entity.prototype.addPlatforming = function (opt) {
        opt = Object.assign({
            width: this.sprite_width,
            height: this.sprite_height,
            margin: 3,
            tag:'',
            on: {}
        }, opt || {})

        let off_x = (this.sprite_width - opt.width)/2;
        let off_x2 = off_x/2;
        let off_y = (this.sprite_height - opt.height)/2;
        let off_y2 = off_y/2;
        let coll_head, coll_feet;

        this.addShape("body",{type:"rect", shape:[off_x,off_y,opt.width,opt.height], color:Draw.red})
		this.addShape("head",{type:"rect", shape:[opt.margin,off_y-4,opt.width-(opt.margin*2),4], color:Draw.green})
		this.addShape("feet",{type:"rect", shape:[opt.margin,opt.height,opt.width-(opt.margin*2),4], color:Draw.green})//opt.margin,opt.height-(opt.margin*2),opt.width-(opt.margin*2),opt.margin], color:Draw.green})
        this.shape_index = "body"
        this.collision_order = ['head','feet','body'];

		this.onCollision['body'] = (other, info) => {
			if (other.tag == opt.tag) {
                coll_head = this.collisions('head').includes(opt.tag);
                coll_feet = this.collisions('feet').includes(opt.tag);
                if (coll_head || coll_feet) {
                    if (coll_head && opt.on.head ? opt.on.head(other, info) : false) return true;
                    if (coll_feet && opt.on.foot ? opt.on.foot(other, info) : false) return true;

                    if (info.sep_vec.x != 0)
                        this.collisionStopX();
                    else
                        this.collisionStopY();
                    this.vspeed = 0;
                } else {
                    if (info.sep_vec.x != 0) {
                        if (opt.on.body ? opt.on.body(other, info) : false) return true;
                        this.collisionStopX();
                    }
                }
            }
		}
    }
})