package entities;

import audio.Audio;
import h2d.filter.Glow;

class Item extends Entity {
    @:s public var kind : Data.ItemKind;
    var item : Data.Item = null;

    public function new(id:String, floorId:Int, tx:Int, ty:Int) {
        this.kind = Data.item.resolve(id).id;
        super("", floorId, tx, ty);
    }

    override public function init(?animName:String=null) {
        super.init(kind.toString());
        isGround = true;
        item = Data.item.get(kind);
        anim.filter = new Glow(0xFFFFFF, .5, 10, 1., 1., true);
    }

    override public function onSteppedOnBy(e:Summon) {
        var isPotion = false;
        if(item.hpAdd > 0) {
            Game.inst.hero.hp += item.hpAdd;
            isPotion = true;
        }
        if(item.mpAdd > 0) {
            Game.inst.hero.mp += item.mpAdd;
            isPotion = true;
        }
        if(kind == key1) {
            Game.inst.inventory.gainKey(1);
            Audio.playSound(Data.SoundKind.itemKey);
        } else if(kind == key2) {
            Game.inst.inventory.gainKey(2);
            Audio.playSound(Data.SoundKind.itemKey);
        } else if(kind == key3) {
            Game.inst.inventory.gainKey(3);
            Audio.playSound(Data.SoundKind.itemKey);
        } else if(kind == scrollSlime) {
            Game.inst.hero.tryPickScroll(slime);
            Audio.playSound(Data.SoundKind.itemScroll);
        } else if(kind == scrollGnome) {
            Game.inst.hero.tryPickScroll(gnome);
            Audio.playSound(Data.SoundKind.itemScroll);
        } else if(kind == scrollDragon) {
            Game.inst.hero.tryPickScroll(dragon);
            Audio.playSound(Data.SoundKind.itemScroll);
        } else if(kind == scrollNone) {
            Game.inst.hero.tryForgetScroll();
            Audio.playSound(Data.SoundKind.itemScroll);
        } else if(kind == swordSmall) {
            Game.inst.hero.atk += 1;
            Audio.playSound(Data.SoundKind.itemBonus);
        } else if(kind == swordLarge) {
            Game.inst.hero.atk += 5;
            Audio.playSound(Data.SoundKind.itemBonus);
        } else if(isPotion) {
            Audio.playSound(Data.SoundKind.itemPotion);
        }
        delete();
        Game.inst.onChange();
    }
}