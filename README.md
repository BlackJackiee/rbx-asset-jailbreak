# rbx-asset-jailbreak

This is a tool / workflow that allows bypassing roblox's constraints regarding the of use other people's assets with editable images / editable meshes. Note that this only works in studio.

As per the documentation:
> To prevent misuse, Create Editable APIs will only allow you to load assets:
> - That are owned by the creator of the experience (if the experience is owned by an individual).
> - That are owned by a group (if the experience is owned by the group).
> - That are owned by the logged in Studio user (if the place file has not yet been saved or published to Roblox).

This tool does respect [privacy settings](https://devforum.roblox.com/t/beta-privacy-for-newly-created-image-mesh-and-decal-assets/3930210) for assets. Any asset not marked for open use cannot be loaded as an editable image / mesh.

It was mainly written to allow me to fiddle with a number of test-cases quickly and easily.

This is likely not of significant use beyond learning purposes / debugging.

## How does it work?

In short, there are two parts to this tool.

The first is a plugin component which does some sanity checks / probing and then sends a request via the http service to lune (the second component). Lune then downloads a copy of the asset and puts it in your studio content folder. From there the plugin can now reference that file via the `rbxasset://` scheme which roblox considers a local asset and thus lets you load as an editable mesh / image.

## How to use?

1. Download the repository and install the toolchain via [rokit.](https://github.com/rojo-rbx/rokit) i.e run `rokit install`
2. Run `lune run wally-install`
3. Run `rojo build plugin.project.json --output plugin.rbxm` and place the resulting rbxm in your local plugins folder then make sure you restart studio.
4. Run `lune run serve` (keep this terminal open while using the plugin)
5. In studio, enable HTTP requests under Game Settings → Security → "Allow HTTP Requests".
6. You can now use the tool in either of two ways:
    - Open the **Asset Jailbreak** panel from the Plugins toolbar — paste an asset ID or `roblox.com` URL into the input and click Run. The panel doubles as a built-in cheat sheet and surfaces inline error messages for the common failure modes (lune server not running, HTTP disabled, unparseable input, unsupported asset type).
    - Or call `_G.jailbreak(link: string | number)` from the command bar, same as before.

## Fork notes

This is a personal fork of [EgoMoose/rbx-asset-jailbreak](https://github.com/EgoMoose/rbx-asset-jailbreak). Changes on top of upstream:

- Added a dockable **Asset Jailbreak** plugin panel (toolbar button → input box + Run button + how-to text + color-coded status area). Source: [`src/Main/Ui.luau`](src/Main/Ui.luau).
- Wired the panel into the plugin entry point ([`src/Builds/Plugin.luau`](src/Builds/Plugin.luau)) — the original `_G.jailbreak` command-bar entry still works unchanged.
