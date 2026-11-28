package com.example.ketnoitinhnguyenvienxemay;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    // Trùng channel_id mà Edge Function notify-sos gửi và meta-data trong AndroidManifest.
    static final String SOS_CHANNEL_ID = "sos_alerts";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        createSosChannel();
    }

    // Kênh mức HIGH để thông báo SOS hiện heads-up và có chuông.
    private void createSosChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationChannel channel = new NotificationChannel(
                SOS_CHANNEL_ID,
                "Cảnh báo SOS",
                NotificationManager.IMPORTANCE_HIGH);
        channel.setDescription("Yêu cầu cứu hộ khẩn cấp ở gần bạn");
        NotificationManager manager = getSystemService(NotificationManager.class);
        if (manager != null) manager.createNotificationChannel(channel);
    }
}
