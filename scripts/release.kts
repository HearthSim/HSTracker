#!/usr/bin/env kscript

//@file:DependsOn("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.3.72")
@file:MavenRepository("gradle-releases", "https://repo.gradle.org/gradle/libs-releases-local/")
@file:DependsOn("com.squareup.okhttp3:okhttp:3.8.1")
@file:DependsOn("com.squareup.moshi:moshi:1.8.0")
@file:DependsOn("org.w3c:dom:2.3.0-jaxb-1.0.6")
@file:DependsOn("com.vladsch.flexmark:flexmark-all:0.42.2")
@file:DependsOn("com.damnhandy:handy-uri-templates:2.1.7")
@file:DependsOn("com.dailymotion.kinta:kinta-lib:0.1.10")
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

        ZipIntegration.zip(input = File(hstrackerAppPath), output = File(hstrackerAppZipPath))
        ZipIntegration.zip(input = File(hstrackerXcarchiveDSYMPath),  output = File(hstrackerDSYMZipPath))
    }
}

val notarizeCommand = object: CliktCommand(name = "notarize") {
    override fun run() {
        Notarization.sendForNotarization(
                bundleId = KintaEnv.getOrFail("BUNDLE_ID"),
                itcProvider = KintaEnv.getOrFail("ITC_PROVIDER"),
                file = File(hstrackerAppZipPath)
        )
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

        AppCenter.uploadApp(
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
        CommandLine.executeOrFail(File(hstracker_dir), "$generateAppcast ${hstracker_dir}/dsa_priv.pem $releaseDir")

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