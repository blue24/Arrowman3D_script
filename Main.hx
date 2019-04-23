// Auto-generated
package ;
class Main {
    public static inline var projectName = 'cdawalt_blender_game';
    public static inline var projectPackage = 'arm';
    public static function main() {
        iron.object.BoneAnimation.skinMaxBones = 17;
        iron.object.LightObject.cascadeCount = 4;
        iron.object.LightObject.cascadeSplitFactor = 0.800000011920929;
        armory.system.Starter.main(
            'scene_splash_screen',
            0,
            false,
            true,
            false,
            1280,
            720,
            1,
            true,
            armory.renderpath.RenderPathCreator.get
        );
    }
}
