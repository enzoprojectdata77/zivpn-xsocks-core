package com.minizivpn.app

import android.content.Context
import java.io.File

object Pdnsd {
    fun getExecutable(context: Context): String {
        return File(context.applicationInfo.nativeLibraryDir, "libpdnsd.so").absolutePath
    }

    fun writeConfig(context: Context, listenPort: Int, upstreamIp: String): String {
        val cacheDir = File(context.filesDir, "pdnsd_cache")
        if (!cacheDir.exists()) cacheDir.mkdirs()
        
        val configFile = File(context.filesDir, "pdnsd.conf")
        
        // Using OpenDNS over port 443 (TCP) to bypass port 53 restrictions and avoid loops
        val conf = """
            global {
                perm_cache=2048;
                cache_dir="${cacheDir.absolutePath}";
                server_ip = 169.254.1.1;
                server_port = $listenPort;
                status_ctl = on;
                query_method=tcp_only; 
                min_ttl=15m;
                max_ttl=1w;
                timeout=10;
                daemon=off;
                verbosity=2;
            }

            server {
                label= "opendns-https-port";
                ip = 208.67.222.222;
                port = 443;
                uptest = none;
                proxy_only=on;
            }

            server {
                label= "opendns-backup";
                ip = 208.67.220.220;
                port = 443;
                uptest = none;
                proxy_only=on;
            }

            rr {
                name=localhost;
                reverse=on;
                a=127.0.0.1;
                owner=localhost;
                soa=localhost,root.localhost,42,86400,900,86400,86400;
            }
        """.trimIndent()
        
        configFile.writeText(conf)
        return configFile.absolutePath
    }
}
