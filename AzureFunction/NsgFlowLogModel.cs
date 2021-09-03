using System;
using System.Collections.Generic;

namespace NSGFlowLogBlobTrigger
{
    public class Flow
    {
        
        public string rule { get; set; }
        public List<Flow2> flows { get; set; }
    }

    public class Flow2
    {
        public string mac { get; set; }
        public List<string> flowTuples { get; set; }
       
    }
    public class Properties
    {
        public int Version { get; set; }
        public List<Flow> flows { get; set; }
    }

    public class Record
    {
        public DateTime time { get; set; }
        public string systemId { get; set; }
        public string macAddress { get; set; }
        public string category { get; set; }
        public string resourceId { get; set; }
        public string operationName { get; set; }
        public Properties properties { get; set; }
    }

    public class NSGFlowLogModel
    {
        public List<Record> records { get; set; }
    }


}
