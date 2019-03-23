module common;

import core.stdc.stdlib : exit;
import std.stdio;
import std.process : spawnShell, wait;

string getOptionArg(string[] args, size_t* index)
{
    (*index)++;
    if (*index >= args.length)
    {
        writefln("Error: option '%s' requires an argument", args[*index - 1]);
        exit(1);
    }
    return args[*index];
}

int tryRun(string command)
{
    writefln("[SHELL] %s", command);
    auto pid = spawnShell(command);
    auto exitCode = wait(pid);
    writeln("--------------------------------------------------------------------------------");
    return exitCode;
}
void run(string command)
{
    auto exitCode = tryRun(command);
    if (exitCode != 0)
    {
        writefln("Error: last command exited with code %s", exitCode);
        exit(exitCode);
    }
}

auto tryExecuteShell(string command)
{
    import std.process : executeShell;

    writefln("[EXEC] %s", command);
    return executeShell(command);
}
string executeShell(string command)
{
    auto result = tryExecuteShell(command);
    if (result.status != 0)
    {
        writeln(result.output);
        writeln("--------------------------------------------------------------------------------");
        writefln("Error: last command exited with code %s", result.status);
        exit(1);
    }
    return result.output;
}