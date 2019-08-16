Updating Versions of Dependencies
=================================

Edit the `pom.xml` file and adjust

  - `parent/version` to the latest parent pom version.
    See the tags of https://github.com/jenkinsci/plugin-pom/ for the
    available version.
  - `properties/jenkins.version` to the Jenkins version you want to support.
    This can result in some sort of search if the Jenkins does depend on
    newer versions than the parent pom.
