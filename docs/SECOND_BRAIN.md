# Obsidian Second Brain

This workspace includes the Agent Skills build of [`eugeniughelbur/obsidian-second-brain`](https://github.com/eugeniughelbur/obsidian-second-brain), pinned to the MIT release and commit in [`third_party/obsidian-second-brain/NOTICE.md`](../third_party/obsidian-second-brain/NOTICE.md). The vendored `.agents/skills/` tree has 47 skills for vault capture and recall, project and task notes, technical decisions, software architecture, research, and maintenance. Codex loads them from the repository without a separate sign-up or account.

The vault is `obsidian-vault/`, a persistent folder of Markdown files mounted into the Obsidian MCP container at `/vault`. There is no Obsidian desktop application or Obsidian account login in the headless service. Obsidian Sync is optional: configure it later in a desktop/mobile Obsidian client if you want that vendor's synchronization. The server-side vault itself remains available without Sync.

After starting Compose, initialize the vault from a Codex session in the repository with the `obsidian-init` skill. Review the generated folder layout and instructions before capturing personal information. Back up `obsidian-vault/` as described in [Operations](OPERATIONS.md); its notes are intentionally excluded from Git.

## Updating the package

Run `scripts/install-second-brain.sh` to rebuild the checked-in Agent Skills tree from the pinned commit. It leaves unrelated skill folders in place. To update to a different upstream commit, set `SECOND_BRAIN_REVISION` explicitly, then review the license, build output, and full Git diff before committing.
