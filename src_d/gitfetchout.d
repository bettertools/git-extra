import std.string : startsWith, stripRight;
import std.format : format;
import std.stdio;

import common : getOptionArg, run, tryExecuteShell, executeShell;
import gitcommon : parseGitShow;

void usage()
{
    writeln("Usage:");
    writeln("    git fetchout <repo> <branch>");
}
void help()
{
    usage();
    writeln();
    writeln("This command fetches a remote branch and checks it out.");
    writeln("If a local branch with the same name already exists, it will");
    writeln("prompt the user to overwrite the local branch.");
    /*
    writeln();
    writeln("Note: this is equivalent to:");
    writeln("    1. git fetch <repo> <branch>");
    writeln("    2. git checkout FETCH_HEAD");
    writeln("    3. git branch -D <branch>");
    writeln("    4. git checkout -b <branch>");
    */
}
int main(string[] args)
{
    args = args[1 .. $];
    if (args.length == 0)
    {
        help();
        return 1;
    }

    {
        auto newArgsLength = 0;
        scope(exit) args.length = newArgsLength;
        for (size_t i = 0; i < args.length; i++)
        {
            auto arg = args[i];
            if (!arg.startsWith("-"))
            {
                args[newArgsLength++] = arg;
            }
            //else if (arg == "-r" || arg == "--repo")
            //    repo = getOptionArg(args, &i);
            else
            {
                writefln("Error: unknown option '%s'", arg);
                usage();
                return 1;
            }
        }
    }
    if (args.length != 2)
    {
        writefln("Error: 'git fetchout' requires 2 arguments but got %s", args.length);
        usage();
        return 1;
    }
    auto repo = args[0];
    auto branch = args[1];
        
    // check if local branch exists and if it is updated
    string gitShowLocalOutput;
    {
        // NOTE the '--' is to let git know it's a revision, not a filename
        auto result = tryExecuteShell(format("git show -s %s --", branch));
        if (result.status != 0)
        {
            writefln("    local branch '%s' does not exist", branch);
            run(format("git fetch %s %s:%s", repo, branch, branch));
            run(format("git checkout %s", branch));
            // Use execute shell to overcome dumb terminal warnings
            // NOTE the '--' is to let git know it's a revision, not a filename
            writeln(executeShell("git show -s HEAD --"));
            return 0;
        }
        gitShowLocalOutput = result.output;
    }

    auto localBranchInfo = parseGitShow(gitShowLocalOutput);
    writefln("    local branch: %s", localBranchInfo.sha);

    run(format("git fetch %s %s", repo, branch));
    // NOTE the '--' is to let git know it's a revision, not a filename
    auto gitShowFetchHead = executeShell("git show -s FETCH_HEAD --");
    auto fetchHeadInfo = parseGitShow(gitShowFetchHead);
    writefln("    remote branch: %s", fetchHeadInfo.sha);
    if (localBranchInfo.sha == fetchHeadInfo.sha)
    {
        writefln("local branch is already up-to-date");
        run(format("git checkout %s", branch));
        return 0;
    }

    writeln("================================================================================");
    writeln("LOCAL_BRANCH");
    writeln("================================================================================");
    write(gitShowLocalOutput);
    writeln("================================================================================");
    writeln("REMOTE_BRANCH");
    writeln("================================================================================");
    write(gitShowFetchHead);
    writeln("--------------------------------------------------------------------------------");
    {
        auto result = promptYesNo("Overwrite LOCAL_BRANCH with REMOTE_BRANCH");
        if (!result)
        {
            return 0;
        }
    }

    run("git checkout FETCH_HEAD");
    run(format("git branch -D %s", branch));
    run(format("git checkout -b %s", branch));
    return 0;
}

auto promptYesNo(string prompt)
{
    for (;;)
    {
        write(prompt, "[y/n]? ");
        stdout.flush();
        auto input = stdin.readln().stripRight();
        if (input == "y")
            return true;
        else if (input == "n")
            return false;
    }
}