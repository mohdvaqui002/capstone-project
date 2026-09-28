import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import jenkins.install.InstallState
import groovy.json.JsonSlurper
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.UserRemoteConfig
import hudson.plugins.git.BranchSpec

def secretFile = new File('/var/lib/jenkins/bootstrap-secrets.json')
if (!secretFile.exists()) return
def secrets = new JsonSlurper().parse(secretFile)
def j = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
realm.createAccount(secrets.username, secrets.password)
j.setSecurityRealm(realm)
def auth = new FullControlOnceLoggedInAuthorizationStrategy()
auth.setAllowAnonymousRead(false)
j.setAuthorizationStrategy(auth)
j.setNumExecutors(1)
def credentials = SystemCredentialsProvider.getInstance()
if (!credentials.getCredentials().any { it.id == 'dockerhub' }) {
  credentials.getCredentials().add(new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL, 'dockerhub', 'Docker Hub publisher', secrets.dockerUser, secrets.dockerToken))
  credentials.save()
}
def job = j.getItem('capstone-pipeline') ?: j.createProject(WorkflowJob, 'capstone-pipeline')
def scm = new GitSCM(
  [new UserRemoteConfig('https://github.com/mohdvaqui002/capstone-project.git', null, null, null)],
  [new BranchSpec('*/main')], false, [], null, null, [])
job.setDefinition(new CpsScmFlowDefinition(scm, 'Jenkinsfile'))
job.setDescription('Build, test, publish immutable image; releases only on the 25th in Asia/Kolkata.')
job.save()
j.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
j.save()
secretFile.delete()
println('Capstone secured Jenkins configuration completed')
