# Lycoris-Rewrite

Rewritten Lycoris - better logging, optimizations, error handling, faster prototyping, and more.

Powered & inspired by parts of Serenity's framework rewritten to the new coding style.

For questions, issues, pull requests, and more...

https://discord.gg/lyc

# Coding Style
Please stick to PascalCase for tables and camelCase for everything else.

For constants, please use SCREAMING_SNAKE_CASE. 

Follow the general style of code - avoid nesting & look at other files to see how things are done.

Make OOP / class files the way which is shown in the codebase.

# Donation
You can support us directly at the links below.

PayPal - https://paypal.me/Blastbrean

CashApp - $yazzy0725

Bitcoin - bc1qamax7wd8hpcgyjxkkf3ust8njjpra728ghqan4

# Downloading Releases
The 'Preprocessed' version contains encrypted timings and modules; as if you were a normal buyer. This version is 'Plug And Play' for ready use.

The 'Bundled' version contains no timings and modules. They must be synced with 'WorkspaceSync.py' with the proper arguments to load them properly. This version is for development and contains a builder.

# Code Smell
A majority of the code will be very clean.

Some code will be especially ugly. The modules are there for rapid development. So, they are extremely smelly. A lot of mistakes were done during development which we hoped to correct in the future.

The 'Ui Library' code is very ugly. We did not care about that file because it was an external dependency.

# Installation

Install Benjamin-Dobell's [luabundler](https://github.com/Benjamin-Dobell/luabundler) tool.

```bash
npm install -g luabundler
```

Go to your `global packages` folder where **global modules** are installed to. This [link to a question](https://stackoverflow.com/questions/5926672/where-does-npm-install-packages) can give you some extra context & assistance if needed.

In **my case**, it's **under the path** (in Windows) as `C:\Users\brean\AppData\Local\pnpm\global\5\.pnpm`, but it is likely **not the same** for you because I use the 'pnpm' package manager.

In **that folder**, we'll be **looking for where** the `moonsharp-luaparse` package is at. 

Once located, go **inside of the folder** and locate the `luaparse.js` file.

Then, **replace that file** with the **patched** one [right here.](https://github.com/Blastbrean/Lycoris-Rewrite/blob/main/luaparse.js)

Finally, this will allow you to **bundle this project** properly with added **continue statement** support.

# Run Locally

To run this project locally, bundle using the command below to bundle the project.

```
CTRL+SHIFT+B -- assuming Visual Studio Code
Read the .vscode folder for the build command if not
```

Finally, load `Output/Bundled.lua` in your favorite executor.


