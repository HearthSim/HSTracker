#!/usr/bin/env kscript

//@file:MavenRepository("mavenLocal", "file:////Users/mbonnin/.m2/")
@file:MavenRepository("mavenCentral", "https://repo1.maven.org/maven2/")
@file:MavenRepository("gradleReleases", "https://repo.gradle.org/gradle/libs-releases-local/")

@file:DependsOn("net.mbonnin.kinta:kinta-lib:0.1.14")
// Replace the above line by the one below when https://github.com/dailymotion/kinta/issues/39 is fixed
// @file:DependsOn("com.dailymotion.kinta:kinta-lib:0.1.14-SNAPSHOT")
@file:DependsOn("com.squareup.okhttp3:okhttp:3.8.1")
@file:DependsOn("com.squareup.moshi:moshi:1.8.0")
@file:DependsOn("com.vladsch.flexmark:flexmark-all:0.42.2")
@file:DependsOn("com.damnhandy:handy-uri-templates:2.1.7")
@file:DependsOn("com.github.ajalt:clikt:2.6.0")


import com.dailymotion.kinta.KintaEnv
import com.dailymotion.kinta.Logger
import com.dailymotion.kinta.helper.okHttpLoggingLevel
import com.dailymotion.kinta.integration.appcenter.AppCenter
import com.dailymotion.kinta.integration.commandline.CommandLine
import com.dailymotion.kinta.integration.github.GithubIntegration
import com.dailymotion.kinta.integration.xcode.Notarization
import com.dailymotion.kinta.integration.xcode.Xcode
import com.dailymotion.kinta.integration.zip.ZipIntegration
import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.subcommands
import com.vladsch.flexmark.html.HtmlRenderer
import com.vladsch.flexmark.parser.Parser
import okhttp3.logging.HttpLoggingInterceptor
import org.w3c.dom.Element
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import com.dailymotion.kinta.helper.newOkHttpClient
import kotlinx.serialization.json.*
import okhttp3.*
import com.dailymotion.kinta.helper.executeOrFail
import java.nio.file.Paths

val hstracker_dir = KintaEnv.getOrFail("HSTRACKER_DIR")

val infoPlistPath = "${hstracker_dir}/HSTracker/Info.plist"
val projectPath = "${hstracker_dir}/HSTracker.xcodeproj/project.pbxproj"
val marketingVersion = Xcode.getMarketingVersion(plistFile = File(infoPlistPath), pbxprojFile = File(projectPath))

val releaseDir =
        "${hstracker_dir}/archive/${marketingVersion}"
val optionsPlistPath = "$releaseDir/options.plist"
val hstrackerPath = "$releaseDir/HSTracker"
val hstrackerAppPath = "$releaseDir/HSTracker.app"
val hstrackerXcarchivePath = "$releaseDir/HSTracker.xcarchive"
val hstrackerXcarchiveDSYMPath = "$releaseDir/HSTracker.xcarchive/dSYMs"
val hstrackerAppZipPath = "$releaseDir/HSTracker.app.zip"
val hstrackerDSYMZipPath = "$releaseDir/HSTracker.dSYMs.zip"

val changelogMdPath = "${hstracker_dir}/CHANGELOG.md"

val generateAppcast = "${KintaEnv.getOrFail("SPARKLE_DIR")}/bin/generate_appcast"
val appCast2ReleaseXmlPath = "$releaseDir/appcast2.xml"

val appCast2XmlPath = "${KintaEnv.getOrFail("HSDECKTRACKER_DIR")}/hstracker/appcast2.xml"

val buildCommand = object: CliktCommand(name = "build") {
    override fun run() {
        val pListContents = """<?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>method</key>
                    <string>developer-id</string>
                </dict>
                </plist>""".trimIndent()

        File(releaseDir).mkdirs()
        File(optionsPlistPath).writeText(pListContents)
        CommandLine.executeOrFail(File(hstracker_dir), "xcodebuild -scheme HSTracker clean")
        CommandLine.executeOrFail(File(hstracker_dir), "xcodebuild -archivePath $hstrackerPath -scheme HSTracker archive")
        CommandLine.executeOrFail(
                File(hstracker_dir),
                "xcodebuild -exportArchive -archivePath $hstrackerXcarchivePath -exportPath $releaseDir -exportOptionsPlist $optionsPlistPath"
        )
        File("$releaseDir/dSYMs").mkdirs()
        CommandLine.executeOrFail(File("$releaseDir/dSYMs"), "unzip $hstracker_dir/downloaded-frameworks/HearthMirror/HearthMirror.framework.dSYM.zip")
        CommandLine.executeOrFail(File("$releaseDir"), "zip -r $hstrackerDSYMZipPath dSYMs/")

        ZipIntegration.zip(input = File(hstrackerAppPath), output = File(hstrackerAppZipPath))
        ZipIntegration.zip(input = File(hstrackerXcarchiveDSYMPath),  output = File(hstrackerDSYMZipPath))
    }
}

val notarizeCommand = object: CliktCommand(name = "notarize") {
    override fun run() {
        val password = password ?: KintaEnv.get(KintaEnv.Var.APPLE_PASSWORD)
        val username = username ?: KintaEnv.get(KintaEnv.Var.APPLE_USERNAME)
        val itcProvider = KintaEnv.getOrFail("ITC_PROVIDER")
        val file = File(hstrackerAppZipPath)

        val command = "xcrun notarytool --submit --apple-id $username --password $password --team-id $itcProvider ${file.absolutePath} --wait"

        val result = CommandLine.output(command = command)

        println("result: $result")

        val id = result.lines().mapNotNull {
            val regex = Regex("\s+id: (.*)")
            val match = regex.matchEntire(it)
            if (match != null) {
                val requestId = match.groupValues[1]
                System.out.println("Notarization Request: ${requestId}")
                requestId
            } else {
              null
            }
        }.first()
    }
}

data class ChangelogEntry(val version: String, val markdown: String)

val releaseCommand = object: CliktCommand(name = "release") {

    private fun toHtml(md: String): String {
        val parser = Parser.builder().build()
        val renderer = HtmlRenderer.builder().build()

        val parsedDocument = parser.parse(md)
        return renderer.render(parsedDocument)
    }

    private fun updateAppCast(versionName: String, markdown: String) {
        val factory = DocumentBuilderFactory.newInstance()
        val builder = factory.newDocumentBuilder()
        val releaseAppcastDocument = builder.parse(File(appCast2ReleaseXmlPath))

        val releaseItems = releaseAppcastDocument.documentElement.getElementsByTagName("item")
        if (releaseItems.length != 1) {
            throw Exception("Appcast has generated too many items ${releaseItems.length}")
        }
        val itemElement = (releaseItems.item(0) as Element)
        val enclosureNode = itemElement.getElementsByTagName("enclosure").item(0)
        (enclosureNode as Element).setAttribute(
                "url",
                "https://github.com/HearthSim/HSTracker/releases/download/$versionName/HSTracker.app.zip"
        )

        val appcastDocument = builder.parse(File(appCast2XmlPath))

        val importedNode = appcastDocument.importNode(itemElement, true)
        val pubDate = (importedNode as Element).getElementsByTagName("pubDate").item(0)
        val description = appcastDocument.createElement("description")
        description.textContent = toHtml(markdown)
        importedNode.insertBefore(description, pubDate.nextSibling)
        val channelNode = appcastDocument.documentElement.getElementsByTagName("channel").item(0)
        channelNode.insertBefore(importedNode, channelNode.firstChild)

        val result = StreamResult(File(appCast2XmlPath))
        val tf = TransformerFactory.newInstance()
        val transformer = tf.newTransformer()
        transformer.transform(DOMSource(appcastDocument), result)
    }

    private fun getChangelog(): List<ChangelogEntry> {
        val lines = File(changelogMdPath).readLines()

        val markdownLines = mutableListOf<String>()
        var currentVersion: String? = null

        val list = mutableListOf<ChangelogEntry>()
        val regex = Regex("# (.*)")
        lines.forEach {
            val matchResult = regex.matchEntire(it)
            if (matchResult != null) {
                if (currentVersion != null) {
                    list.add(ChangelogEntry(currentVersion!!, markdownLines.joinToString("\n")))
                }
                currentVersion = matchResult.groupValues[1]
                markdownLines.clear()
            } else {
                markdownLines.add(it)
            }
        }
        if (currentVersion != null) {
            list.add(ChangelogEntry(currentVersion!!, markdownLines.joinToString("\n")))
        }

        return list
    }

    fun uploadApp(
            token: String? = null,
            organization: String? = null,
            appId: String,
            destinationName: String,
            file: File,
            changelog: String?) {

        val json = Json {
            ignoreUnknownKeys = true
        }

        val token = token ?: KintaEnv.getOrFail(KintaEnv.Var.APPCENTER_TOKEN)
        val organisation = organization ?: KintaEnv.getOrFail(KintaEnv.Var.APPCENTER_ORGANIZATION)

        val request = Request.Builder()
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .header("X-API-Token", token)
                .post(RequestBody.create(null, ByteArray(0)))
                .url("https://api.appcenter.ms/v0.1/apps/$organisation/$appId/uploads/releases")
                .build()

        Logger.i("Getting AppCenter upload url...")
        val response = request.executeOrFail()

        var resstr = response.string()
        println("Response $resstr")
        val uploadUrlData = json.parseToJsonElement(resstr).jsonObject
        var file_size_bytes = file.length()
        println("File size is $file_size_bytes")

        var releases_id = uploadUrlData["id"]?.jsonPrimitive?.content ?: error("cannot find id")
        var package_asset_id = uploadUrlData["package_asset_id"]?.jsonPrimitive?.content ?: error("cannot find package_asset_id")
        var url_encoded_token =  uploadUrlData["url_encoded_token"]?.jsonPrimitive?.content ?: error("cannot find url_encoded_token")

        Logger.i("Creating metadata")
        
        var meta_request = Request.Builder()
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .header("X-API-Token", token)
                .post(RequestBody.create(null, ByteArray(0)))
                .url("https://file.appcenter.ms/upload/set_metadata/$package_asset_id?file_name=$appId.app.zip&file_size=$file_size_bytes&token=$url_encoded_token&content_type=application/octet-stream")
                .build()

        var response2 = meta_request.executeOrFail()
        var metastr = response2.string()
        var meta_response = json.parseToJsonElement(metastr).jsonObject

        println("Response for chunks is $metastr")

        var chunk_size = meta_response["chunk_size"]?.jsonPrimitive?.content?.toInt() ?: error("cannot find chunk_size")

        Logger.i("Chunk size $chunk_size")

        var content = file.readBytes()

        Logger.i("Uploading chunked binary")

        var remaining = file_size_bytes

        var block_number = 1
        var offset = 0
        while (remaining > 0)
        {
                println("start uploading chunk $block_number")
                var size = if (remaining > chunk_size) chunk_size else remaining
                var chunk_request = Request.Builder()
                    .header("Content-Length", size.toString())
                    .header("Content-Type", "application/octet-stream")
                    .post(RequestBody.create(null, content, offset, size.toInt()))
                    .url("https://file.appcenter.ms/upload/upload_chunk/$package_asset_id?token=$url_encoded_token&block_number=$block_number")
                    .build()
                val chunk_response = chunk_request.executeOrFail()
                block_number = block_number + 1
                offset = offset + chunk_size
                remaining -= chunk_size
        }

        Logger.i("Finalizing upload")

        var final_request = Request.Builder()
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .header("X-API-Token", token)
            .post(RequestBody.create(null, ByteArray(0)))
            .url("https://file.appcenter.ms/upload/finished/$package_asset_id?token=$url_encoded_token")
            .build()

        var final_response = final_request.executeOrFail()

        Logger.i("Committing release")

        var commit_url = "https://api.appcenter.ms/v0.1/apps/$organisation/$appId/uploads/releases/$releases_id"
        var commit_request = Request.Builder()
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .header("X-API-Token", token)
            .patch(RequestBody.create(null, "{\"upload_status\": \"uploadFinished\", \"id\": \"$releases_id\"}"))
            .url(commit_url)
            .build()

         var commit_response = commit_request.executeOrFail()

         Logger.i("Polling for release ID")

         var counter = 0
         var release_id: String? = null
         while (release_id == null && counter < 15)
         {
                var poll_request = Request.Builder()
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .header("X-API-Token", token)
                    .url(commit_url)
                    .get()
                    .build()
                var poll_response = poll_request.executeOrFail()
                var pollStr = poll_response.string()
                println("Poll response $pollStr")
                var release_response = json.parseToJsonElement(pollStr).jsonObject

                release_id = release_response["release_distinct_id"]?.jsonPrimitive?.content

                if(release_id != null) break

                counter = counter + 1
                try {
                    Thread.sleep(3000)
                } catch(e: InterruptedException) {}
         }

         if (release_id == null) error("Failed to get release id")
         val changelog = getChangelog()

         if (changelog.isEmpty()) {
            throw Exception("Changelog is empty :-/")
         }

         val changelogVersion = changelog.first().version

         println("changelogVersion=$changelogVersion")
         println("plistVersion=$marketingVersion")

         if (changelogVersion != marketingVersion) {
            throw Exception("versions do not match, either update the CHANGELOG.md or Info.plist")
         }

         Logger.i("Distributing build")


         var postData = JsonObject(mapOf(
                  "destinations" to JsonArray(listOf(JsonObject(mapOf("name" to JsonPrimitive("All-users-of-HSTracker"))))),
                  "notify_testers" to JsonPrimitive(true),
                  "release_notes" to JsonPrimitive(changelog.first().markdown)
                  )
         ).toString()
 
         var distribute_url = "https://api.appcenter.ms/v0.1/apps/$organisation/$appId/releases/$release_id"

         println("Distribute url $distribute_url, post data $postData")

         var distribute_request = Request.Builder()
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .header("X-API-Token", token)
            .patch(RequestBody.create(null, postData))
            .url(distribute_url)
            .build()

         var distribute_response = distribute_request.executeOrFail()
         println("Distribute execute done")
         var dist_str = distribute_response.string()
         println("Distribute response $dist_str")

         Logger.i("Completed AppCenter release")
    }

    override fun run() {
        println("Releasing HSTracker")

        val changelog = getChangelog()

        if (changelog.isEmpty()) {
            throw Exception("Changelog is empty :-/")
        }

        val changelogVersion = changelog.first().version

        println("changelogVersion=$changelogVersion")
        println("plistVersion=$marketingVersion")

        if (changelogVersion != marketingVersion) {
            throw Exception("versions do not match, either update the CHANGELOG.md or Info.plist")
        }

        println("uploading $hstrackerDSYMZipPath")

        AppCenter.uploadDsym(
                appId = "HSTracker",
                dsymFile = File(hstrackerDSYMZipPath)
        )

        println("uploading $hstrackerAppZipPath")

        uploadApp(
                appId = "HSTracker",
                file = File(hstrackerAppZipPath),
                changelog = changelog.first().markdown,
                destinationName = "All-users-of-HSTracker"
        )

        GithubIntegration.createRelease(
                tagName = changelogVersion,
                assets = listOf(
                        File(hstrackerAppZipPath)
                ),
                changelogMarkdown = changelog.first().markdown
        )

        // not sure why we need to remove the sparkle cache but we do else it reuses previous versions
        CommandLine.executeOrFail(File(hstracker_dir), "rm -rf ${System.getenv("HOME")}/Library/Caches/Sparkle_generate_appcast/")
        // generateAppCast will output some warnings, that's ok at this point
        // Warning: Private key not found in the Keychain (-25300). Please run the generate_keys tool
        // Could not unarchive /Users/martin/git/HSTracker/archive/2019_6_6/options.plist Error Domain=SUSparkleErrorDomain Code=3000 "Not a supported archive format: file:///Users/martin/Library/Caches/Sparkle_generate_appcast/options.plist.tmp/options.plist" UserInfo={NSLocalizedDescription=Not a supported archive format: file:///Users/martin/Library/Caches/Sparkle_generate_appcast/options.plist.tmp/options.plist}
        CommandLine.executeOrFail(File(hstracker_dir), "$generateAppcast -f ${hstracker_dir}/dsa_priv.pem $releaseDir")

        val hsdecktracker_net_dir = File(KintaEnv.getOrFail("HSTRACKER_HSDECKTRACKER_DIR"))

        CommandLine.executeOrFail(hsdecktracker_net_dir, "git checkout master")
        CommandLine.executeOrFail(hsdecktracker_net_dir, "git pull")
        CommandLine.executeOrFail(hsdecktracker_net_dir, "git stash")
        updateAppCast(marketingVersion, changelog.first().markdown)    }
}

val testCommand = object : CliktCommand(name = "test") {
    override fun run() {

        println("uploading $hstrackerDSYMZipPath")
        AppCenter.uploadDsym(
                appId = "HSTracker",
                dsymFile = File(hstrackerDSYMZipPath)
        )
    }
}
fun main(args: Array<String>) {
    Logger.level = Logger.LEVEL_INFO
    okHttpLoggingLevel = HttpLoggingInterceptor.Level.NONE

    object : CliktCommand() {
        override fun run() {

        }
    }.subcommands(
            buildCommand,
            notarizeCommand,
            releaseCommand,
            testCommand
    ).main(args)
}

main(args)