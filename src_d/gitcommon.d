module gitcommon;

import std.string : startsWith;
import std.algorithm : findAmong;
//import std.datetime;
import std.stdio;
import core.stdc.stdlib : exit;

struct GitShowInfo
{
    string sha;
    string datetime;  
}
GitShowInfo parseGitShow(string output)
{
   enum CommitPrefix = "commit ";
   if (!output.startsWith(CommitPrefix))
   {
       writefln("Error: expected `git show` output to start with \"%s\" but it didn't:", CommitPrefix);
       writeln(output);
       exit(1);
   }
   output = output[CommitPrefix.length .. $];
   auto afterCommit = output.findAmong("\r\n");
   if (afterCommit.length == 0)
   {
       writeln("Error: expected `git show` output to contain newline after commit but none was found:");
       writeln(output);
       exit(1);
   }
   return GitShowInfo(output[0 .. afterCommit.ptr - output.ptr]);
}