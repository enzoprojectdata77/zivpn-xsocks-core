package com.minizivpn.app

import android.content.Context
import android.telephony.CellInfoLte
import android.telephony.CellInfoNr
import android.telephony.CellSignalStrengthNr
import android.telephony.TelephonyManager
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import android.util.Log

class NetworkProbe(private val context: Context) {

    fun getSmartConfig(): Map<String, Int> {
        val score = getNetworkScore()
        
        // Algoritma Penentuan RecvWindow
        // Score 0-100
        
        val recvWin: Int
        val recvConn: Int
        
        if (score >= 80) {
            // Excellent Signal -> Throughput Mode
            recvWin = 655360
            recvConn = 262144
        } else if (score >= 50) {
            // Good/Fair Signal -> Balanced Mode
            recvWin = 327680
            recvConn = 131072
        } else {
            // Poor Signal -> Latency Mode (Conservative)
            recvWin = 163840
            recvConn = 65536
        }
        
        return mapOf(
            "score" to score,
            "recv_win" to recvWin,
            "recv_conn" to recvConn
        )
    }

    private fun getNetworkScore(): Int {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        
        if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.e("NetworkProbe", "Missing Location Permission")
            return 50 // Default to Balanced if no permission
        }

        try {
            val allCellInfo = tm.allCellInfo
            if (allCellInfo.isNullOrEmpty()) return 50

            // Prioritize registered cells
            val cell = allCellInfo.firstOrNull { it.isRegistered } ?: allCellInfo[0]

            var rsrp = -140
            var sinr = -20
            var type = "UNKNOWN"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && cell is CellInfoNr) {
                type = "5G"
                val signal = cell.cellSignalStrength as CellSignalStrengthNr
                rsrp = signal.ssRsrp
                sinr = signal.ssSinr
            } else if (cell is CellInfoLte) {
                type = "4G"
                val signal = cell.cellSignalStrength
                rsrp = signal.rsrp
                sinr = signal.rssnr
            } else {
                // WiFi or 3G, assume balanced
                return 60
            }

            // Scoring Logic
            // RSRP: -80 or better is great (100), -120 is bad (0)
            val rsrpScore = normalize(rsrp, -120, -80)
            
            // SINR: 20 or better is great (100), 0 is bad (0)
            val sinrScore = normalize(sinr, 0, 20)

            // Weight: 40% RSRP, 60% SINR (Quality matters more for throughput)
            val finalScore = (rsrpScore * 0.4 + sinrScore * 0.6).toInt()
            
            Log.d("NetworkProbe", "Type: $type, RSRP: $rsrp, SINR: $sinr, Score: $finalScore")
            return finalScore

        } catch (e: Exception) {
            Log.e("NetworkProbe", "Error probing network: ${e.message}")
            return 50
        }
    }

    private fun normalize(value: Int, min: Int, max: Int): Int {
        if (value >= max) return 100
        if (value <= min) return 0
        return ((value - min).toDouble() / (max - min) * 100).toInt()
    }
}
