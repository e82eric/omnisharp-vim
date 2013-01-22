using NUnit.Framework;
using Should;
namespace Omnisharp.Tests
{
    public class NamespaceCompletions : CompletionTestBase
    {
        [Test]
        public void Should_not_break_with_empty_file()
        {
            DisplayTextFor("$").ShouldBeEmpty();
        }

        [Test]
        public void Should_complete_using()
        {
            DisplayTextFor("usi$").ShouldContainOnly("using");
        }

        [Test]
        public void Should_complete_namespace()
        {
            DisplayTextFor("name$").ShouldContainOnly("namespace");
        }

        [Test]
        public void Should_complete_namespace2()
        {
            DisplayTextFor(
                @"using System;
                  name$").ShouldContainOnly("namespace");
        }

        [Test]
        public void Should_complete_system()
        {
            DisplayTextFor("using $").ShouldContain("System");
        }

        [Test]
        public void Should_complete_system_only()
        {
            DisplayTextFor("using Sys$").ShouldContainOnly("System");
        }

        [Test]
        public void Should_complete_diagnostics()
        {
            DisplayTextFor("using System.$").ShouldContain("Diagnostics");
        }

        [Test]
        public void Should_complete_diagnostics_only()
        {
            DisplayTextFor("using System.diag$").ShouldContainOnly("Diagnostics");
        }
    }
}