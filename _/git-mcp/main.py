from fastmcp import FastMCP
import git
import os

# Initialize the server
mcp = FastMCP("CustomGit")

@mcp.tool()
def git_init(repo_path: str) -> str:
  """Initialize a git repository if it doesn't exist."""
  try:
    # Check if already a git repository
    if os.path.exists(os.path.join(repo_path, '.git')):
      return f"Repository already exists at {repo_path}"
    
    # Initialize new repository
    git.Repo.init(repo_path)
    return f"Initialized git repository at {repo_path}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_status(repo_path: str) -> str:
  """Get the current git status of a local repository. 
  Use absolute paths like /Users/name/project."""
  try:
    repo = git.Repo(repo_path)
    return repo.git.status()
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_diff_unstaged(repo_path: str) -> str:
  """Show changes in the working directory that are not yet staged."""
  try:
    repo = git.Repo(repo_path)
    return repo.git.diff(None)
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_add(repo_path: str, file_path: str = ".") -> str:
  """Add files to staging area. Use '.' for all files."""
  try:
    repo = git.Repo(repo_path)
    repo.index.add([file_path])
    return f"Added {file_path} to staging area"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_commit(repo_path: str, message: str) -> str:
  """Create a commit with the given message."""
  try:
    repo = git.Repo(repo_path)
    repo.index.commit(message)
    return f"Commit created: {message}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_log(repo_path: str, limit: int = 10) -> str:
  """Show commit history."""
  try:
    repo = git.Repo(repo_path)
    return repo.git.execute(
      ["git", "-C", repo_path, "log", "--oneline", f"-n{limit}"]
    )
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_branch(repo_path: str, branch_name: str = "") -> str:
  """List branches if no name provided, create new branch otherwise."""
  try:
    repo = git.Repo(repo_path)
    if branch_name:
      repo.create_head(branch_name)
      return f"Created branch: {branch_name}"
    else:
      return repo.git.branch("-a")
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_checkout(repo_path: str, branch_or_file: str) -> str:
  """Switch to a branch or checkout a file."""
  try:
    repo = git.Repo(repo_path)
    repo.git.checkout(branch_or_file)
    return f"Checked out: {branch_or_file}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_push(repo_path: str, remote: str = "origin", branch: str = "main") -> str:
  """Push changes to remote repository."""
  try:
    repo = git.Repo(repo_path)
    origin = repo.remote(remote)
    origin.push(branch)
    return f"Pushed {branch} to {remote}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_pull(repo_path: str, remote: str = "origin", branch: str = "main") -> str:
  """Pull changes from remote repository."""
  try:
    repo = git.Repo(repo_path)
    origin = repo.remote(remote)
    origin.pull(branch)
    return f"Pulled {branch} from {remote}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_diff_staged(repo_path: str) -> str:
  """Show changes that are staged for commit."""
  try:
    repo = git.Repo(repo_path)
    return repo.git.diff("--cached")
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_reset(repo_path: str, mode: str = "soft", commit: str = "HEAD") -> str:
  """Reset repository. Mode: soft, mixed, or hard. Handles uncommit even if only one commit exists."""
  try:
    repo = git.Repo(repo_path)

    if mode not in ["soft", "mixed", "hard"]:
      return f"Invalid reset mode: {mode}"

    # count commits
    try:
      commit_count = int(repo.git.rev_list("--count", "HEAD"))
    except Exception:
      return "Error: Repository has no commits."

    # special case: only one commit and user tries HEAD~1
    if commit in ["HEAD~1", "HEAD^"] and commit_count == 1:
      repo.git.update_ref("-d", "HEAD")

      if mode == "soft":
        repo.git.reset("--soft")
      elif mode == "mixed":
        repo.git.reset("--mixed")
      elif mode == "hard":
        repo.git.reset("--hard")

      return f"Uncommitted initial commit using {mode} reset"

    repo.git.reset(f"--{mode}", commit)
    return f"Reset {mode} to {commit}"

  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_remote_list(repo_path: str) -> str:
  """List all remote repositories."""
  try:
    repo = git.Repo(repo_path)
    return repo.git.remote("-v")
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_remote_add(repo_path: str, name: str, url: str) -> str:
  """Add a remote repository."""
  try:
    repo = git.Repo(repo_path)
    repo.create_remote(name, url)
    return f"Added remote {name}: {url}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_stash(repo_path: str, action: str = "push", message: str = "") -> str:
  """Stash changes. Actions: push, pop, list, clear."""
  try:
    repo = git.Repo(repo_path)
    if action == "push":
      if message:
        repo.git.stash("push", "-m", message)
      else:
        repo.git.stash("push")
      return "Changes stashed"
    elif action == "pop":
      repo.git.stash("pop")
      return "Stash popped"
    elif action == "list":
      return repo.git.stash("list")
    elif action == "clear":
      repo.git.stash("clear")
      return "Stash cleared"
    else:
      return f"Invalid stash action: {action}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_merge(repo_path: str, branch: str) -> str:
  """Merge a branch into current branch."""
  try:
    repo = git.Repo(repo_path)
    repo.git.merge(branch)
    return f"Merged branch: {branch}"
  except Exception as e:
    return f"Error: {str(e)}"

@mcp.tool()
def git_tag(repo_path: str, tag_name: str = "", commit: str = "HEAD") -> str:
  """List tags if no name provided, create tag otherwise."""
  try:
    repo = git.Repo(repo_path)
    if tag_name:
      repo.create_tag(tag_name, commit)
      return f"Created tag: {tag_name}"
    else:
      return repo.git.tag("-l")
  except Exception as e:
    return f"Error: {str(e)}"

if __name__ == "__main__":
  mcp.run()