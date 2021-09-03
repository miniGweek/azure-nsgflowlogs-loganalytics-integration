using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace NSGFlowLogBlobTrigger
{
    public class AzureLogAnalyticsClient
    {
        private readonly string _workspaceId;
        private readonly string _sharedKey;
        private readonly static HttpClient _client = new HttpClient();

        public string TimeStampField { get; set; } = "time";

        public AzureLogAnalyticsClient(string customerId, string sharedKey)
        {
            _workspaceId = customerId;
            _sharedKey = sharedKey;
        }

      
        public async Task WriteLog(string logName, string logMessage)
        {
            var datestring = DateTime.UtcNow.ToString("r");
            var jsonBytes = Encoding.UTF8.GetBytes(logMessage);
            string stringToHash = "POST\n" + jsonBytes.Length + "\napplication/json\n" + "x-ms-date:" + datestring + "\n/api/logs";
            string hashedString = BuildSignature(stringToHash, _sharedKey);
            string signature = "SharedKey " + _workspaceId + ":" + hashedString;

            await PostData(signature, datestring, logName, logMessage);
        }

        // Build the API signature
        public static string BuildSignature(string message, string secret)
        {
            var encoding = new System.Text.ASCIIEncoding();
            byte[] keyByte = Convert.FromBase64String(secret);
            byte[] messageBytes = encoding.GetBytes(message);
            using (var hmacsha256 = new HMACSHA256(keyByte))
            {
                byte[] hash = hmacsha256.ComputeHash(messageBytes);
                return Convert.ToBase64String(hash);
            }
        }

        // Send a request to the POST API endpoint
        public async Task PostData(string signature, string date, string logName, string json)
        {

            string url = "https://" + _workspaceId + ".ods.opinsights.azure.com/api/logs?api-version=2016-04-01";
            _client.DefaultRequestHeaders.Clear();
            _client.DefaultRequestHeaders.Add("Accept", "application/json");
            _client.DefaultRequestHeaders.Add("Log-Type", logName);
            _client.DefaultRequestHeaders.Add("Authorization", signature);
            _client.DefaultRequestHeaders.Add("x-ms-date", date);
            _client.DefaultRequestHeaders.Add("time-generated-field", TimeStampField);
            
            HttpContent httpContent = new StringContent(json, Encoding.UTF8);
            httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            var response = await _client.PostAsync(new Uri(url), httpContent);

            var responseContent = response.Content;
            string result = await responseContent.ReadAsStringAsync();
        }
    }
}
