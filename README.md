# Default Repository Configuration

## Dependencies
- This project uses `luau lsp`, `selene` and `stylua` to provide a cleaner method of linting and module fetching.
- We use `Rojo` to connect our repository with Roblox.
- We use `Aftman` and `Wally` to install dependencies.

Make sure you have the following installed in your machine:
- `VS Code`
- `Rust`

## To setup the project

#### Extensions

- Get the `Luau LSP` extension: (https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp)
- Get the `Selene` extension: (https://marketplace.visualstudio.com/items?itemName=Kampfkarren.selene-vscode)
- Get the `StyLua` extension: (https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua)

#### Install Aftman

If you’ve followed this guide at least once, you already have `Aftman` installed! You can skip to the next session. The easiest way to install our tools is with `Aftman`, and the easiest way to install that is with `Rust` in your machine.

**Warning**: If you run into issues with `Aftman`, you may try using `brew` instead, especially if you are on a Mac. Also, if commands like `wally` do not appear for you, confirm that the necessary commands were added to your system's environment path.

Go ahead and open a new folder or existing repository, and open as a VS Code project.

Open a 'git bash' terminal in your VS Code.

- Type `cargo install aftman`: This will install the latest version of aftman.
- Type `aftman install`: This will install the core dependencies in `aftman.toml`. These are useful tools like Rojo and Selene.

#### Initialize Wally Packages

Wally is already in the project, but isn’t doing anything yet, we need to install the dependencies listed in `wally.toml` with the following command. You should see a Packages folder appear in the directory as the dependencies get added.

- Type `wally install`: This will install the project dependencies in `wally.toml`. These are packages that this project uses.

#### Lune Commands and Rojo

Now, you are finally ready to use `Rojo` to sync with Roblox. You may type `Cntrl + Shift + P` and type Rojo to find its commands, or you may call the Lune script. Using Lune is the recommended path for this project in particular because it is already set up to work with multiple places. It also makes sure to update `sourcemap.json` whenever a new file changes, which is crucial for linting and autocompletion.

- Type `lune run scripts/setup`. Then type the command you want. To start syncing with Rojo, choose 1, then type the name of the world you want to sync to.

Now, whenever you save a script, the rojo sourcemap will be updated and Rojo will keep your changes synced with studio.

You may stop Lune with `Cntrl + C`.

#### When Connecting to Roblox Studio

You may notice that you cannot actually sync Rojo to any Roblox Experience, and that is because we have a security measure implemented that defines the valid places for each `project.json` file.

You should add your [Dev] Place, or any place really, that you want to sync, to the "servePlaceIds" entry in the correct `project.json` file. For projects that contain multiple `project.json` files, this security measure prevents us from accidentally syincing to the incorrect Roblox experience.

Once added, you may easily sync Rojo again and the Experience should be accepted.

### Commander Admins List

Add your Roblox ID to the file "Admins"

### Cautions

- You may not edit code directly in Roblox Studio, your changes will be lost.
- You may not add any object, like a BasePart or a model, to a Rojo-synced folder, or your changes will be lost.
- `Luau LSP` will sometimes not function correctly, especially if you change the location of your folders and scripts. You may open the commands and choose `Luau: Reload Language Server`.
- Same thing with Rojo: If it breaks for you, pause Lune, restart it, or use the Rojo commands in VS Code.