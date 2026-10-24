import jenkins.model.*
import hudson.tools.*
import hudson.tasks.Maven

// Declare l'outil "maven" (utilise par "tools { maven 'maven' }" dans le Jenkinsfile)
// Maven est installe dans l'image (apt) : on pointe vers /usr/share/maven.
def inst = Jenkins.get().getDescriptorByType(Maven.DescriptorImpl)
inst.setInstallations(new Maven.MavenInstallation("maven", "/usr/share/maven", []))
inst.save()
