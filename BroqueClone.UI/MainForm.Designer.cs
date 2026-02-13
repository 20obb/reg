namespace BroqueClone.UI
{
    partial class MainForm
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.grpDeviceInfo = new System.Windows.Forms.GroupBox();
            this.lblStatus = new System.Windows.Forms.Label();
            this.lblModel = new System.Windows.Forms.Label();
            this.lblSerial = new System.Windows.Forms.Label();
            this.lblECID = new System.Windows.Forms.Label();
            this.grpOperations = new System.Windows.Forms.GroupBox();
            this.btnActivate = new System.Windows.Forms.Button();
            this.btnChangeSerial = new System.Windows.Forms.Button();
            this.btnBoot = new System.Windows.Forms.Button();
            this.btnCheckm8 = new System.Windows.Forms.Button();
            this.txtLog = new System.Windows.Forms.TextBox();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.progressBar = new System.Windows.Forms.ToolStripProgressBar();
            this.lblStatusText = new System.Windows.Forms.ToolStripStatusLabel();

            this.grpDeviceInfo.SuspendLayout();
            this.grpOperations.SuspendLayout();
            this.statusStrip1.SuspendLayout();
            this.SuspendLayout();

            // 
            // grpDeviceInfo
            // 
            this.grpDeviceInfo.Controls.Add(this.lblStatus);
            this.grpDeviceInfo.Controls.Add(this.lblModel);
            this.grpDeviceInfo.Controls.Add(this.lblSerial);
            this.grpDeviceInfo.Controls.Add(this.lblECID);
            this.grpDeviceInfo.Location = new System.Drawing.Point(12, 12);
            this.grpDeviceInfo.Name = "grpDeviceInfo";
            this.grpDeviceInfo.Size = new System.Drawing.Size(776, 100);
            this.grpDeviceInfo.TabIndex = 0;
            this.grpDeviceInfo.TabStop = false;
            this.grpDeviceInfo.Text = "Device Information";

            // Labels checks
            this.lblECID.AutoSize = true;
            this.lblECID.Location = new System.Drawing.Point(16, 25);
            this.lblECID.Name = "lblECID";
            this.lblECID.Size = new System.Drawing.Size(36, 15);
            this.lblECID.Text = "ECID: -";

            this.lblSerial.AutoSize = true;
            this.lblSerial.Location = new System.Drawing.Point(16, 50);
            this.lblSerial.Name = "lblSerial";
            this.lblSerial.Size = new System.Drawing.Size(38, 15);
            this.lblSerial.Text = "Serial: -";

            this.lblModel.AutoSize = true;
            this.lblModel.Location = new System.Drawing.Point(300, 25);
            this.lblModel.Name = "lblModel";
            this.lblModel.Size = new System.Drawing.Size(44, 15);
            this.lblModel.Text = "Model: -";

            this.lblStatus.AutoSize = true;
            this.lblStatus.Location = new System.Drawing.Point(300, 50);
            this.lblStatus.Name = "lblStatus";
            this.lblStatus.Size = new System.Drawing.Size(42, 15);
            this.lblStatus.Text = "Status: Disconnected";

            // 
            // grpOperations
            // 
            this.grpOperations.Controls.Add(this.btnActivate);
            this.grpOperations.Controls.Add(this.btnChangeSerial);
            this.grpOperations.Controls.Add(this.btnBoot);
            this.grpOperations.Controls.Add(this.btnCheckm8);
            this.grpOperations.Location = new System.Drawing.Point(12, 118);
            this.grpOperations.Name = "grpOperations";
            this.grpOperations.Size = new System.Drawing.Size(200, 300);
            this.grpOperations.TabIndex = 1;
            this.grpOperations.TabStop = false;
            this.grpOperations.Text = "Operations";

            // Buttons
            this.btnCheckm8.Location = new System.Drawing.Point(6, 22);
            this.btnCheckm8.Name = "btnCheckm8";
            this.btnCheckm8.Size = new System.Drawing.Size(188, 40);
            this.btnCheckm8.TabIndex = 0;
            this.btnCheckm8.Text = "1. Pwn DFU (Checkm8)";
            this.btnCheckm8.UseVisualStyleBackColor = true;
            this.btnCheckm8.Click += new System.EventHandler(this.btnCheckm8_Click);

            this.btnBoot.Location = new System.Drawing.Point(6, 68);
            this.btnBoot.Name = "btnBoot";
            this.btnBoot.Size = new System.Drawing.Size(188, 40);
            this.btnBoot.TabIndex = 1;
            this.btnBoot.Text = "2. Boot Ramdisk";
            this.btnBoot.UseVisualStyleBackColor = true;
            this.btnBoot.Click += new System.EventHandler(this.btnBoot_Click);

            this.btnChangeSerial.Location = new System.Drawing.Point(6, 114);
            this.btnChangeSerial.Name = "btnChangeSerial";
            this.btnChangeSerial.Size = new System.Drawing.Size(188, 40);
            this.btnChangeSerial.TabIndex = 2;
            this.btnChangeSerial.Text = "3. Change Serial";
            this.btnChangeSerial.UseVisualStyleBackColor = true;
            this.btnChangeSerial.Click += new System.EventHandler(this.btnChangeSerial_Click);

            this.btnActivate.Location = new System.Drawing.Point(6, 160);
            this.btnActivate.Name = "btnActivate";
            this.btnActivate.Size = new System.Drawing.Size(188, 40);
            this.btnActivate.TabIndex = 3;
            this.btnActivate.Text = "4. Activate (Bypass)";
            this.btnActivate.UseVisualStyleBackColor = true;
            this.btnActivate.Click += new System.EventHandler(this.btnActivate_Click);

            // 
            // txtLog
            // 
            this.txtLog.Location = new System.Drawing.Point(218, 118);
            this.txtLog.Multiline = true;
            this.txtLog.Name = "txtLog";
            this.txtLog.ReadOnly = true;
            this.txtLog.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtLog.Size = new System.Drawing.Size(570, 300);
            this.txtLog.TabIndex = 2;
            this.txtLog.BackColor = System.Drawing.Color.Black;
            this.txtLog.ForeColor = System.Drawing.Color.Lime;
            this.txtLog.Font = new System.Drawing.Font("Consolas", 9F);

            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.progressBar,
            this.lblStatusText});
            this.statusStrip1.Location = new System.Drawing.Point(0, 428);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(800, 22);
            this.statusStrip1.TabIndex = 3;

            // 
            // progressBar
            // 
            this.progressBar.Name = "progressBar";
            this.progressBar.Size = new System.Drawing.Size(100, 16);

            // 
            // lblStatusText
            // 
            this.lblStatusText.Name = "lblStatusText";
            this.lblStatusText.Size = new System.Drawing.Size(39, 17);
            this.lblStatusText.Text = "Ready";

            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 450);
            this.Controls.Add(this.statusStrip1);
            this.Controls.Add(this.txtLog);
            this.Controls.Add(this.grpOperations);
            this.Controls.Add(this.grpDeviceInfo);
            this.Name = "MainForm";
            this.Text = "BroqueClone - Cleanup Crew Edition";
            this.Load += new System.EventHandler(this.MainForm_Load);
            this.grpDeviceInfo.ResumeLayout(false);
            this.grpDeviceInfo.PerformLayout();
            this.grpOperations.ResumeLayout(false);
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();
        }

        private System.Windows.Forms.GroupBox grpDeviceInfo;
        private System.Windows.Forms.Label lblStatus;
        private System.Windows.Forms.Label lblModel;
        private System.Windows.Forms.Label lblSerial;
        private System.Windows.Forms.Label lblECID;
        private System.Windows.Forms.GroupBox grpOperations;
        private System.Windows.Forms.Button btnActivate;
        private System.Windows.Forms.Button btnChangeSerial;
        private System.Windows.Forms.Button btnBoot;
        private System.Windows.Forms.Button btnCheckm8;
        private System.Windows.Forms.TextBox txtLog;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripProgressBar progressBar;
        private System.Windows.Forms.ToolStripStatusLabel lblStatusText;
    }
}
