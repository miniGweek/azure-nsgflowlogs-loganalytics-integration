using System;
using System.Collections.Generic;
using System.Text;

namespace SXiQTest.Function
{
    internal class TimeRecord
    {
        public DateTime TimeGenerated { get; set; }
        public string MacAddress { get; set; }
        public string ResourceId { get; set; }
        public string Rule { get; set; }
        public DateTime TimeWhenOcurred { get; set; }
        public string SourceIP { get; set; }
        public string DestinationIp { get; set; }
        public string SourcePort { get; set; }
        public string DestinationPort { get; set; }
        public string Protocol { get; set; }
        public string TrafficFlow { get; set; }
        public string TrafficDecision { get; set; }
        public string FlowState { get; set; }
        public string PacketsSourceToDestination { get; set; }
        public string BytessentSourceToDestination { get; set; }
        public string PacketsDestinationToSource { get; set; }
        public string BytessentDestinationToSource { get; set; }
    }
}
