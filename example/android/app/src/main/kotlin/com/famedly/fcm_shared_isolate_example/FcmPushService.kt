package com.famedly.fcm_shared_isolate_example

import android.content.Context
import com.famedly.fcm_shared_isolate.FcmSharedIsolateService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint

class FcmPushService : FcmSharedIsolateService() {
    override fun getEngine(): FlutterEngine {
        return provideEngine(applicationContext)
    }

    companion object {
        fun provideEngine(context: Context): FlutterEngine {
            var engine = MainActivity.engine
            if (engine == null) {
                engine = MainActivity.provideEngine(context)
                engine.localizationPlugin.sendLocalesToFlutter(
                    context.resources.configuration
                )
                engine.dartExecutor.executeDartEntrypoint(
                    DartEntrypoint.createDefault()
                )
            }
            return engine
        }
    }
}
