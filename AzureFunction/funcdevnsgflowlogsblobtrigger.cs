using System;
using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Collections.Generic;

namespace SXiQTest.Function
{
    public static class funcdevnsgflowlogsblobtrigger
    {
        [FunctionName("funcdevnsgflowlogsblobtrigger")]
        public static void Run([BlobTrigger("insights-logs-networksecuritygroupflowevent/{name}", Connection = "stsxiqdevnsgflowlogs_STORAGE")] String myBlob, string name, ILogger log)
        {
            log.LogInformation($"C# Blob trigger function Processed blob\n Name:{name} \n Size: {myBlob.Length} Bytes");

            var blobData = JsonSerializer.Deserialize<Root>(myBlob);
            var records = new List<TimeRecord>();
            var loganalyticsWorkspaceId = GetEnvironmentVariable("loganalyticsWorkspaceId");
            var loganalyticsWorkspaceKey = GetEnvironmentVariable("loganalyticsWorkspaceKey");
            var loganalyticsClient = new AzureLogAnalyticsClient(loganalyticsWorkspaceId, loganalyticsWorkspaceKey);

            foreach (var value in blobData.records)
            {
                foreach (var NSGFlowRecord in value.properties.flows)
                {
                    foreach (var flow in NSGFlowRecord.flows)
                    {
                        foreach (var flowtuple in flow.flowTuples)
                        {
                            var flowTupleMembers = flowtuple.Split(",");
                            var timeRecord = new TimeRecord()
                            {
                                TimeGenerated = value.time,
                                MacAddress = value.macAddress,
                                ResourceId = value.resourceId,
                                Rule = NSGFlowRecord.rule,
                                TimeWhenOcurred = DateTimeOffset.FromUnixTimeSeconds(Convert.ToInt32(flowTupleMembers[0])).DateTime,
                                SourceIP = flowTupleMembers[1],
                                DestinationIp = flowTupleMembers[2],
                                SourcePort = flowTupleMembers[3],
                                DestinationPort = flowTupleMembers[4],
                                Protocol = flowTupleMembers[5],
                                TrafficFlow = flowTupleMembers[6],
                                TrafficDecision = flowTupleMembers[7],
                                FlowState = flowTupleMembers[8],
                                PacketsSourceToDestination = flowTupleMembers[9],
                                BytessentSourceToDestination = flowTupleMembers[10],
                                PacketsDestinationToSource = flowTupleMembers[11],
                                BytessentDestinationToSource = flowTupleMembers[12],
                            };
                            records.Add(timeRecord);
                        }
                    }

                }
            }
            var recordJsonString = JsonSerializer.Serialize(records);
            loganalyticsClient.WriteLog("DevTest_NSGFlowLogs", recordJsonString);
        }

        private static string GetEnvironmentVariable(string name)
        {
            return System.Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }
    }    
}
